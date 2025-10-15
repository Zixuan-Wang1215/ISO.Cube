import SwiftUI

struct PythonTestView: View {
    @State private var isRunning: Bool = false
    @State private var output: String = ""
    @State private var process: Process? = nil

    // Absolute path to the python script in the workspace
    private let scriptPath: String = "/Users/iso.hi/Documents/Code/ISO.Cube/test_raw_data.py"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    if isRunning {
                        stopProcess()
                    } else {
                        runScript()
                    }
                }) {
                    Text(isRunning ? "Stop" : "Run test_raw_data.py")
                }
                .keyboardShortcut(.defaultAction)

                Spacer()
            }

            ScrollView {
                Text(output.isEmpty ? "(no output)" : output)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(8)
            }
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .onDisappear {
            stopProcess()
        }
    }

    private func runScript() {
        output = ""
        // Print environment diagnostics to help identify which Python Xcode is using
        output.append("[env] Collecting Python environment info...\n")
        let pyenvPython = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".pyenv/versions/3.12.3/bin/python").path
        output.append("[env] using interpreter: \(pyenvPython)\n")
        output.append(runQuickPythonInfo(python: pyenvPython))

        let task = Process()
        // Use specified pyenv interpreter
        task.executableURL = URL(fileURLWithPath: pyenvPython)
        task.arguments = [scriptPath]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe

        let outputHandle = stdoutPipe.fileHandleForReading
        let errorHandle = stderrPipe.fileHandleForReading

        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let chunk = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    output.append(contentsOf: chunk)
                }
            }
        }

        errorHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let chunk = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    output.append(contentsOf: chunk)
                }
            }
        }

        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                isRunning = false
                process = nil
            }
        }

        do {
            try task.run()
            process = task
            isRunning = true
        } catch {
            output.append("Failed to start process: \(error)\n")
            isRunning = false
            process = nil
        }
    }

    private func runQuickCommand(executable: String, arguments: [String]) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run() } catch { return "[env] Failed to run \(executable): \(error)\n" }
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return "" }
        return text.hasSuffix("\n") ? text : text + "\n"
    }

    private func runQuickPythonInfo(python: String) -> String {
        let code = "import sys, os; print('[env] sys.executable =', sys.executable); print('[env] version =', sys.version); print('[env] PATH =', os.environ.get('PATH',''))"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: python)
        task.arguments = ["-c", code]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run() } catch { return "[env] Failed to query python info: \(error)\n" }
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return "" }
        return text.hasSuffix("\n") ? text : text + "\n"
    }

    private func stopProcess() {
        guard let task = process else { return }
        output.append("\n[stopping process]\n")
        task.terminate()
        task.waitUntilExit()
        process = nil
        isRunning = false
    }
}

#Preview {
    PythonTestView()
}


