
import SwiftUI
import SceneKit

struct RotationTestView: NSViewRepresentable {
    // Binding to start/stop the Python BLE bridge
    @Binding var isRunningPython: Bool
    // Callback to receive Python stdout/stderr lines
    var onPythonOutput: (String) -> Void = { _ in }
    class Coordinator {
        // Rotation manager for cube operations
        var rotationManager: CubeRotationManager?
        // Timer for automatic rotation testing
        var timer: DispatchSourceTimer?
        // Python BLE bridge process
        var process: Process?
        var stdoutHandle: FileHandle?
        var stderrHandle: FileHandle?
        // Save initial camera state for reset when needed
        var initialCameraTransform: SCNMatrix4?
        var initialCameraPosition: SCNVector3?
        var initialCameraSaturation: CGFloat?
        // Output forwarding and running state setter
        var onOutput: ((String) -> Void)?
        var setRunning: ((Bool) -> Void)?
        deinit {
            timer?.cancel()
            timer = nil
            stopPythonBridge()
        }

        func startPythonBridge() {
            // Absolute paths used to avoid sandbox path issues
            let pythonPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".pyenv/versions/3.12.3/bin/python").path
            let scriptPath = "/Users/iso.hi/Documents/Code/ISO.Cube/test_raw_data.py"

            let task = Process()
            task.executableURL = URL(fileURLWithPath: pythonPath)
            task.arguments = [scriptPath]

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            task.standardOutput = stdoutPipe
            task.standardError = stderrPipe

            let outHandle = stdoutPipe.fileHandleForReading
            let errHandle = stderrPipe.fileHandleForReading

            outHandle.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
                // Parse lines like: "Move: R, Serial: 12" or "Move: U' , Serial: ..."
                chunk.split(separator: "\n").forEach { lineSub in
                    let line = lineSub.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !line.isEmpty else { return }
                    // Forward raw output lines to UI
                    self?.onOutput?(line + "\n")
                    if line.hasPrefix("Move:") {
                        // Extract move token between "Move:" and "," if present
                        var moveToken = line.replacingOccurrences(of: "Move:", with: "")
                        if let commaIdx = moveToken.firstIndex(of: ",") {
                            moveToken = String(moveToken[..<commaIdx])
                        }
                        moveToken = moveToken.trimmingCharacters(in: .whitespaces)
                        // Forward to manager on main queue
                        if let mgr = self?.rotationManager, !moveToken.isEmpty {
                            DispatchQueue.main.async {
                                mgr.applyMove(moveToken)
                            }
                        }
                    }
                }
            }

            errHandle.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                if !data.isEmpty, let chunk = String(data: data, encoding: .utf8) {
                    self?.onOutput?(chunk)
                }
            }

            task.terminationHandler = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.stdoutHandle?.readabilityHandler = nil
                    self?.stderrHandle?.readabilityHandler = nil
                    self?.process = nil
                    self?.stdoutHandle = nil
                    self?.stderrHandle = nil
                    self?.setRunning?(false)
                }
            }

            do {
                try task.run()
                self.process = task
                self.stdoutHandle = outHandle
                self.stderrHandle = errHandle
                self.setRunning?(true)
            } catch {
                // Failed to start python bridge; ignore for now
                self.setRunning?(false)
            }
        }

        func stopPythonBridge() {
            guard let task = process else { return }
            task.terminate()
            task.waitUntilExit()
            stdoutHandle?.readabilityHandler = nil
            stderrHandle?.readabilityHandler = nil
            process = nil
            stdoutHandle = nil
            stderrHandle = nil
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)

        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = NSColor.clear

        // Load scene
        let scene = SCNScene(named: "3dcube.scn")!
        scnView.scene = scene

        // Find cube node
        let cubeNode = scene.rootNode.childNode(withName: "cube", recursively: true)!

        // Find camera node and initialize its properties
        let cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)!
        let cam = cameraNode.camera!
        cam.wantsHDR = true
        cam.saturation = 1.0

        // Move camera further away
        let onCubePos = SCNVector3(Float(20.83), Float(20.759), Float(20.83))
        cameraNode.position = onCubePos

        // Save initial camera state
        context.coordinator.initialCameraTransform = cameraNode.transform
        context.coordinator.initialCameraPosition = cameraNode.position
        context.coordinator.initialCameraSaturation = CGFloat(cam.saturation)

        // Create rotation manager
        let manager = CubeRotationManager(cubeNode: cubeNode, scene: scene)
        context.coordinator.rotationManager = manager
        // Wire output sink and running state setter
        context.coordinator.onOutput = onPythonOutput
        context.coordinator.setRunning = { running in
            DispatchQueue.main.async {
                self.$isRunningPython.wrappedValue = running
            }
        }
        // Start Python BLE move stream only if requested
        if isRunningPython {
            context.coordinator.startPythonBridge()
        }

        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        // Start/stop Python process based on binding state
        if isRunningPython {
            if context.coordinator.process == nil {
                context.coordinator.startPythonBridge()
            }
        } else {
            if context.coordinator.process != nil {
                context.coordinator.stopPythonBridge()
            }
        }
    }

    static func dismantleNSView(_ nsView: SCNView, coordinator: Coordinator) {
        // Clean up resources when view is dismantled
        coordinator.timer?.cancel()
        coordinator.timer = nil
        coordinator.rotationManager = nil
        coordinator.stopPythonBridge()
    }
}

// SwiftUI wrapper with a button to start/stop the Python BLE bridge and a log area.
struct RotationTestScreen: View {
    @State private var isRunningPython: Bool = false
    @State private var logText: String = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { isRunningPython.toggle() }) {
                    Text(isRunningPython ? LocalizationKey.stop.localized : LocalizationKey.connectAndStream.localized)
                }
                Spacer()
            }
            .padding(.horizontal)

            RotationTestView(isRunningPython: $isRunningPython) { line in
                logText.append(line)
                if !line.hasSuffix("\n") { logText.append("\n") }
            }
            .frame(height: 520)

            ScrollView {
                Text(logText.isEmpty ? LocalizationKey.noOutput.localized : logText)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(8)
            }
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
}
