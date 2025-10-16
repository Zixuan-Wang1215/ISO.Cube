import SwiftUI
import AppKit
import CoreBluetooth

enum TimerState { case idle, armed, ready, running }
enum Tab { case timing, history, settings }

// MARK: - Placeholder Views
struct HistoryView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Text("History")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Text("Settings")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Tab Button
typealias TabButtonLabel = String
struct TabButton: View {
    let label: TabButtonLabel
    let tab: Tab
    @Binding var selectedTab: Tab

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                selectedTab = tab
            }
        }) {
            Text(label)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                .frame(width: 40, height: 40)
                .background(
                    ZStack {
                        if selectedTab == tab {
                            // Liquid glass effect for selected state
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.4),
                                                    Color.white.opacity(0.1),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: -1)
                        } else {
                            // Subtle glass effect for unselected state
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        }
                    }
                )
                .scaleEffect(selectedTab == tab ? 1.0 : 0.95)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var selectedTab: Tab = .timing
    @State private var timerState: TimerState = .idle
    // Bluetooth logic moved here
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var showingDevicePicker = false
    @State private var pythonProcess: Process? = nil
    @State private var isConnectedToCube = false
    @State private var moveOutput = ""
    @State private var isCubeConfirmed = false

    private var selectedTabIndex: Int {
        switch selectedTab {
        case .timing: return 0
        case .history: return 1
        case .settings: return 2
        }
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    TimerView(timerState: $timerState, isCubeConfirmed: $isCubeConfirmed, moveOutput: moveOutput)
                        .frame(width: geo.size.width, height: geo.size.height)
                    HistoryView()
                        .frame(width: geo.size.width, height: geo.size.height)
                    SettingsView()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .offset(x: -CGFloat(selectedTabIndex) * geo.size.width)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }

            // bottom tab bar
            VStack {
                Spacer()
                let buttonWidth: CGFloat = 40
                let tabSpacing: CGFloat = 0 // tightly grouped
                let btSpacing: CGFloat = 0 // tightly grouped
                let capsuleSpacing: CGFloat = 18 // space between tab and BT groups
                let tabBarHeight: CGFloat = 50
                let tabBarPadding: CGFloat = 12
                let tabCornerRadius: CGFloat = 25
                let tabBarBgOpacity = 0.9

                // Unified bottom bar: two capsule groups, minimal space between
                HStack(alignment: .center, spacing: capsuleSpacing) {
                    // Capsule group: T/H/S buttons
                    HStack(spacing: tabSpacing) {
                        TabButton(label: "T", tab: .timing, selectedTab: $selectedTab)
                        TabButton(label: "H", tab: .history, selectedTab: $selectedTab)
                        TabButton(label: "S", tab: .settings, selectedTab: $selectedTab)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: tabBarHeight)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(tabBarBgOpacity))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                    )

                    // Capsule group: Bluetooth + X buttons
                    HStack(spacing: btSpacing) {
                        Button(action: {
                            showingDevicePicker = true
                            bluetoothManager.startScanning()
                        }) {
                            Image(nsImage: NSImage(named: NSImage.bluetoothTemplateName)!)
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(isConnectedToCube ? .blue : .gray)
                                .frame(width: 24, height: 24)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(PlainButtonStyle())
                        if isConnectedToCube {
                            Button(action: { disconnectFromCube() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                    .padding(.trailing, 6)
                                    .padding(.leading, 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(height: tabBarHeight)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(tabBarBgOpacity))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .opacity(timerState == .running ? 0 : 1)
                .frame(maxWidth: .infinity)

                // Move output overlay (optional: show at bottom)
                if !moveOutput.isEmpty && timerState != .running {
                    ScrollView {
                        Text(moveOutput)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(8)
                    }
                    .frame(height: 100)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showingDevicePicker) {
            DevicePickerView(bluetoothManager: bluetoothManager) { device in
                connectToDevice(device)
                showingDevicePicker = false
            }
        }
    }

    // MARK: - Python Connection
    private func connectToDevice(_ device: CBPeripheral) {
        pythonProcess?.terminate()
        pythonProcess = nil

        let pythonPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".pyenv/versions/3.12.3/bin/python").path
        let scriptPath = "/Users/iso.hi/Documents/Code/ISO.Cube/test_raw_data.py"

        let task = Process()
        task.executableURL = URL(fileURLWithPath: pythonPath)
        task.arguments = [scriptPath, device.identifier.uuidString]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let chunk = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { 
                    self.moveOutput.append(chunk)
                    // 检查是否是连接确认消息
                    if chunk.contains("CUBE_CONNECTED_CONFIRMATION") {
                        self.handleCubeConnectedConfirmation()
                    }
                }
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let chunk = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { self.moveOutput.append(chunk) }
            }
        }

        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.isConnectedToCube = false
                self.pythonProcess = nil
            }
        }

        do {
            try task.run()
            pythonProcess = task
            isConnectedToCube = true
            moveOutput = "Connecting to \(device.name ?? "Unknown Device")...\n"
        } catch {
            moveOutput.append("Failed to connect: \(error)\n")
        }
    }

    private func disconnectFromCube() {
        pythonProcess?.terminate()
        pythonProcess = nil
        isConnectedToCube = false
        moveOutput = ""
        isCubeConfirmed = false
    }
    
    private func handleCubeConnectedConfirmation() {
        isCubeConfirmed = true
        print("Cube connection confirmed - updating 3D view settings")
    }
}

// MARK: - TimerView
struct TimerView: View {
    @StateObject private var timerVM = TimerViewModel()
    @Binding var timerState: TimerState
    @Binding var isCubeConfirmed: Bool
    let moveOutput: String
    @State private var readyWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 0) {
            // Top scramble
            VStack(spacing: 16) {
                CubeScrambleView(scramble: timerVM.currentScramble)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 200)
            .padding(.horizontal)
            .padding(.top, 20)
            .opacity(timerState == .running ? 0 : 1)

            // Timer text
            VStack(spacing: 0) {
                Text(timerVM.displayTime)
                    .foregroundColor(timerState == .armed ? .red : timerState == .ready ? .green : .white)
                    .font(.system(size: timerState == .running ? 90 : 72, weight: .light, design: .monospaced))
                    .padding(.bottom, 40)
            }
            .padding(.top, 100)

            // Cube3DView visual only, no Bluetooth UI
            ZStack(alignment: .bottom) {
                Cube3DView(isTimerRunning: timerState == .running, isCubeConfirmed: isCubeConfirmed, moveOutput: moveOutput)
                    .frame(width: 2560, height: 600)
                    .offset(y: -40)
                    .opacity(timerState == .running ? 0 : 1)
                    .allowsHitTesting(false)
            }
            .frame(height: 500)
        }
        .frame(minWidth: 600, minHeight: 800)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
                if event.keyCode == 49 {
                    switch event.type {
                    case .keyDown:
                        if timerState == .idle {
                            timerState = .armed
                            let work = DispatchWorkItem {
                                if timerState == .armed {
                                    timerState = .ready
                                }
                            }
                            readyWorkItem = work
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
                        } else if timerState == .running {
                            timerVM.toggleTimer()
                            timerState = .idle
                            readyWorkItem?.cancel()
                        }
                    case .keyUp:
                        if timerState == .armed {
                            readyWorkItem?.cancel()
                            timerState = .idle
                        } else if timerState == .ready {
                            timerState = .running
                            timerVM.toggleTimer()
                        }
                    default: break
                    }
                    return nil
                }
                if timerState == .running && event.type == .keyDown {
                    timerVM.toggleTimer()
                    timerState = .idle
                    readyWorkItem?.cancel()
                    return nil
                }
                return event
            }
        }
    }
}

// MARK: - Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var isScanning = false
    private var centralManager: CBCentralManager?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard let central = centralManager, central.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        isScanning = true
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {}

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        if let name = peripheral.name, name.uppercased().hasPrefix("GAN") {
            DispatchQueue.main.async {
                if !self.discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                    self.discoveredDevices.append(peripheral)
                }
            }
        }
    }
}

// MARK: - Device Picker Sheet
struct DevicePickerView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.dismiss) private var dismiss
    let onDeviceSelected: (CBPeripheral) -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("GAN Cube Devices")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    bluetoothManager.stopScanning()
                    dismiss()
                }
            }
            .padding()

            if bluetoothManager.isScanning {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Scanning for GAN devices...")
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            if bluetoothManager.discoveredDevices.isEmpty && !bluetoothManager.isScanning {
                Text("No GAN devices found")
                    .foregroundColor(.secondary)
                    .padding()
            }

            List(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                Button(action: { onDeviceSelected(device) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name ?? "Unknown Device")
                            .font(.headline)
                        Text("ID: \(device.identifier.uuidString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }

            HStack {
                Button("Refresh") { bluetoothManager.startScanning() }
                    .disabled(bluetoothManager.isScanning)
                Spacer()
                Button("Stop Scanning") { bluetoothManager.stopScanning() }
                    .disabled(!bluetoothManager.isScanning)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .onDisappear { bluetoothManager.stopScanning() }
    }
}
