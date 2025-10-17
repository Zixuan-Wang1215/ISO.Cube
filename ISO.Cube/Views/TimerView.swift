import SwiftUI
import AppKit
import CoreBluetooth

enum TimerState { case idle, inspecting, armed, ready, running }
enum Tab { case timing, history, settings }

// MARK: - Average Detail View
struct AverageDetailView: View {
    let title: String
    let solves: [SolveModel]
    let onSolveTap: (SolveModel) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    onClose()
                }
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color.black)
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Solve list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(solves.reversed()) { solve in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(solve.displayTime)
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                if !solve.scramble.isEmpty {
                                    Text(solve.scramble)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            if solve.penalty == 2000 {
                                Text("+2")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            } else if solve.penalty == -1 {
                                Text("DNF")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .onTapGesture {
                            onSolveTap(solve)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 500)
        .background(Color.black)
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}

// MARK: - History View
struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @State private var selectedSolve: SolveModel? = nil
    @State private var showingResultConfirmation = false
    @State private var showingAverageDetail = false
    @State private var averageDetailTitle = ""
    @State private var averageDetailSolves: [SolveModel] = []
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with session name
                VStack(spacing: 8) {
                    Text(historyManager.currentSession?.name ?? "No Session")
                        .font(.title)
                        .fontWeight(.semibold)
                .foregroundColor(.white)
                    
                    // Statistics
                    if let stats = historyManager.getSessionStatistics(for: historyManager.currentSessionId ?? "") {
                        VStack(spacing: 12) {
                            // First row - Basic statistics and current averages
                            HStack(spacing: 20) {
                                // Basic statistics
                                StatItem(label: "Solves", value: "\(stats.solveCount)")
                                if let avg = stats.averageTime {
                                    StatItem(label: "Avg", value: String(format: "%.2f", avg))
                                }
                                StatItem(label: "DNF", value: "\(stats.dnfCount)")
                                StatItem(label: "+2", value: "\(stats.plus2Count)")
                                
                                // Vertical separator
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 1, height: 40)
                                
                                // Current averages
                                if let session = historyManager.currentSession {
                                    StatItem(label: "Mo3", value: formatAverage(session.meanOf3()), valueColor: getAverageColor(session.meanOf3()), onTap: {
                                        if let solves = session.getCurrentMeanOf3Solves() {
                                            averageDetailTitle = "Current Mo3"
                                            averageDetailSolves = solves
                                            showingAverageDetail = true
                                        }
                                    })
                                    StatItem(label: "Ao5", value: formatAverage(session.averageOf5()), valueColor: getAverageColor(session.averageOf5()), onTap: {
                                        if let solves = session.getCurrentAverageOf5Solves() {
                                            averageDetailTitle = "Current Ao5"
                                            averageDetailSolves = solves
                                            showingAverageDetail = true
                                        }
                                    })
                                    StatItem(label: "Ao12", value: formatAverage(session.averageOf12()), valueColor: getAverageColor(session.averageOf12()), onTap: {
                                        if let solves = session.getCurrentAverageOf12Solves() {
                                            averageDetailTitle = "Current Ao12"
                                            averageDetailSolves = solves
                                            showingAverageDetail = true
                                        }
                                    })
                                    StatItem(label: "Ao50", value: formatAverage(session.averageOf50()), valueColor: getAverageColor(session.averageOf50()), onTap: {
                                        if let solves = session.getCurrentAverageOf50Solves() {
                                            averageDetailTitle = "Current Ao50"
                                            averageDetailSolves = solves
                                            showingAverageDetail = true
                                        }
                                    })
                                    StatItem(label: "Ao100", value: formatAverage(session.averageOf100()), valueColor: getAverageColor(session.averageOf100()), onTap: {
                                        if let solves = session.getCurrentAverageOf100Solves() {
                                            averageDetailTitle = "Current Ao100"
                                            averageDetailSolves = solves
                                            showingAverageDetail = true
                                        }
                                    })
                                }
                            }
                            
                            // Second row - Best times (purple color)
                            HStack(spacing: 20) {
                                if let best = stats.bestTime {
                                    StatItem(label: "Best Single", value: formatTime(best), valueColor: .purple, onTap: {
                                        // Find the best solve and show confirmation
                                        if let session = historyManager.currentSession {
                                            let bestSolve = session.solves.min { solve1, solve2 in
                                                let time1 = solve1.time + solve1.penalty
                                                let time2 = solve2.time + solve2.penalty
                                                return time1 < time2 && solve1.penalty != -1
                                            }
                                            if let solve = bestSolve {
                                                selectedSolve = solve
                                                showingResultConfirmation = true
                                            }
                                        }
                                    })
                                }
                                
                                if let session = historyManager.currentSession {
                                    StatItem(label: "Best Mo3", value: formatAverage(session.bestMeanOf3()), valueColor: .purple, onTap: {
                                        if let solves = session.getBestMeanOf3Solves() {
                                            averageDetailTitle = "Best Mo3"
                                            averageDetailSolves = solves
                                            showingAverageDetail = true
                                        }
                                    })
                                    StatItem(label: "Best Ao5", value: formatAverage(session.bestAverageOf5()), valueColor: .purple, onTap: {
                                        if let solves = session.getBestAverageOf5Solves() {
                                            averageDetailTitle = "Best Ao5"
                                            averageDetailSolves = solves
                                            showingAverageDetail = true
                                        }
                                    })
                                    StatItem(label: "Best Ao12", value: formatAverage(session.bestAverageOf12()), valueColor: .purple, onTap: {
                                        if let solves = session.getBestAverageOf12Solves() {
                                            averageDetailTitle = "Best Ao12"
                                            averageDetailSolves = solves
                                            showingAverageDetail = true
                                        }
                                    })
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Scrollable solve list
                if let session = historyManager.currentSession, !session.solves.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(session.solves.reversed()) { solve in
                                SolveRowView(solve: solve, onTap: {
                                    selectedSolve = solve
                                    showingResultConfirmation = true
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Space for tab bar
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("No solves yet")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                    }
                }
            }
        }
        .overlay(
            // Result confirmation overlay for history editing
            Group {
                if showingResultConfirmation, let solve = selectedSolve {
                    ResultConfirmationView(
                        solve: solve,
                        onConfirm: { penalty, comment, scramble in
                            updateSolveInHistory(solve: solve, penalty: penalty, comment: comment, scramble: scramble)
                            showingResultConfirmation = false
                            selectedSolve = nil
                        },
                        onCancel: {
                            showingResultConfirmation = false
                            selectedSolve = nil
                        },
                        onDelete: {
                            deleteSolveFromHistory(solve: solve)
                            showingResultConfirmation = false
                            selectedSolve = nil
                        }
                    )
                }
                
                // Average detail overlay
                if showingAverageDetail {
                    ZStack {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingAverageDetail = false
                            }
                        
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                AverageDetailView(
                                    title: averageDetailTitle,
                                    solves: averageDetailSolves,
                                    onSolveTap: { solve in
                                        selectedSolve = solve
                                        showingAverageDetail = false
                                        showingResultConfirmation = true
                                    },
                                    onClose: {
                                        showingAverageDetail = false
                                    }
                                )
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
        )
    }
    
    private func formatTime(_ timeInMilliseconds: Int) -> String {
        let seconds = Double(timeInMilliseconds) / 1000.0
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        let milliseconds = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%03d", minutes, remainingSeconds, milliseconds)
        } else {
            return String(format: "%d.%03d", remainingSeconds, milliseconds)
        }
    }
    
    private func formatAverage(_ average: Double?) -> String {
        guard let avg = average else { return "-" }
        
        // Special case for DNF average
        if avg == -1 {
            return "DNF"
        }
        
        if avg >= 60 {
            let minutes = Int(avg) / 60
            let seconds = avg.truncatingRemainder(dividingBy: 60)
            return String(format: "%d:%.3f", minutes, seconds)
        } else {
            return String(format: "%.3f", avg)
        }
    }
    
    private func getAverageColor(_ average: Double?) -> Color {
        guard let avg = average else { return .white }
        
        // DNF average is red
        if avg == -1 {
            return .red
        }
        
        // Normal average is white
        return .white
    }
    
    private func updateSolveInHistory(solve: SolveModel, penalty: Int, comment: String, scramble: String) {
        // Find and update the solve in the current session
        guard let sessionId = historyManager.currentSessionId,
              let sessionIndex = historyManager.sessions.firstIndex(where: { $0.id == sessionId }),
              let solveIndex = historyManager.sessions[sessionIndex].solves.firstIndex(where: { $0.id == solve.id }) else {
            return
        }
        
        // Create updated solve
        let updatedSolve = SolveModel(
            penalty: penalty,
            time: solve.time,
            scramble: scramble,
            comment: comment,
            timestamp: solve.timestamp
        )
        
        // Update the solve in the session
        historyManager.sessions[sessionIndex].solves[solveIndex] = updatedSolve
        
        // Save to file
        historyManager.saveHistory()
    }
    
    private func deleteSolveFromHistory(solve: SolveModel) {
        // Find and remove the solve from the current session
        guard let sessionId = historyManager.currentSessionId,
              let sessionIndex = historyManager.sessions.firstIndex(where: { $0.id == sessionId }),
              let solveIndex = historyManager.sessions[sessionIndex].solves.firstIndex(where: { $0.id == solve.id }) else {
            return
        }
        
        // Remove the solve from the session
        historyManager.sessions[sessionIndex].solves.remove(at: solveIndex)
        
        // Save to file
        historyManager.saveHistory()
    }
}

// MARK: - Stat Item View
struct StatItem: View {
    let label: String
    let value: String
    let valueColor: Color
    let onTap: (() -> Void)?
    
    init(label: String, value: String, valueColor: Color = .white, onTap: (() -> Void)? = nil) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.onTap = onTap
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundColor(valueColor)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .onTapGesture {
            onTap?()
        }
        .opacity(onTap != nil ? 1.0 : 0.8)
    }
}

// MARK: - Solve Row View
struct SolveRowView: View {
    let solve: SolveModel
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Time display
            HStack(spacing: 4) {
                if solve.penalty == -1 {
                    // DNF case
                    Text("DNF")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.red)
                } else if solve.penalty == 2000 {
                    // +2 case - show original time with +2 on the right
                    HStack(spacing: 4) {
                        Text(solve.displayTime)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.orange)
                        Text("+2")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(3)
                    }
                } else {
                    // Normal case
                    Text(solve.displayTime)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                }
            }
            
            // Date
            Text(solve.formattedDate)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isHovered ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(isHovered ? 0.3 : 0.1), lineWidth: isHovered ? 1 : 0.5)
                )
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .shadow(color: .black.opacity(isHovered ? 0.2 : 0.0), radius: isHovered ? 8 : 0, x: 0, y: isHovered ? 4 : 0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovered = hovering
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
            // Close session dropdown when tab is clicked
            NotificationCenter.default.post(name: .init("SessionDropdownShouldClose"), object: nil)
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
    @StateObject private var historyManager = HistoryManager()
    @State private var showingDevicePicker = false
    @State private var pythonProcess: Process? = nil
    @State private var isConnectedToCube = false
    @State private var moveOutput = ""
    @State private var isCubeConfirmed = false
    @State private var isSessionDropdownExpanded = false
    @State private var isConfirmationWindowShowing = false
    @State private var hasTriggeredSwipe = false

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
                    TimerView(historyManager: historyManager, timerState: $timerState, isCubeConfirmed: $isCubeConfirmed, moveOutput: moveOutput, isSessionDropdownExpanded: $isSessionDropdownExpanded, isConfirmationWindowShowing: $isConfirmationWindowShowing)
                        .frame(width: geo.size.width, height: geo.size.height)
                    HistoryView(historyManager: historyManager)
                        .frame(width: geo.size.width, height: geo.size.height)
                    SettingsView()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .offset(x: -CGFloat(selectedTabIndex) * geo.size.width)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                .gesture(
                    DragGesture(minimumDistance: 5, coordinateSpace: .local)
                        .onChanged { value in
                            let translation = value.translation
                            let velocity = value.velocity
                            
                            // Real-time swipe detection during drag - only trigger once per gesture
                            if !hasTriggeredSwipe && abs(translation.width) > abs(translation.height) && abs(translation.width) > 30 && abs(velocity.width) > 100 {
                                hasTriggeredSwipe = true
                                
                                if translation.width > 0 {
                                    // Swipe right - go to previous tab
                                    switch selectedTab {
                                    case .timing:
                                        break // Already at first tab
                                    case .history:
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                                            selectedTab = .timing
                                        }
                                    case .settings:
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                                            selectedTab = .history
                                        }
                                    }
                                } else {
                                    // Swipe left - go to next tab
                                    switch selectedTab {
                                    case .timing:
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                                            selectedTab = .history
                                        }
                                    case .history:
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                                            selectedTab = .settings
                                        }
                                    case .settings:
                                        break // Already at last tab
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            // Reset trigger flag when drag ends
                            hasTriggeredSwipe = false
                        }
                )
            }

            // bottom tab bar
            VStack {
                Spacer()
                let _: CGFloat = 40
                let tabSpacing: CGFloat = 0 // tightly grouped
                let btSpacing: CGFloat = 0 // tightly grouped
                let _: CGFloat = 18 // space between tab and BT groups
                let tabBarHeight: CGFloat = 50
                let _: CGFloat = 12
                let _: CGFloat = 25
                let tabBarBgOpacity = 0.9

                // Unified bottom bar: three capsule groups with custom spacing
                HStack(alignment: .center, spacing: 0) {
                    // Capsule group: Session dropdown (left)
                    SessionDropdownView(historyManager: historyManager, onExpansionChange: { isExpanded in
                        isSessionDropdownExpanded = isExpanded
                    })
                        .frame(height: tabBarHeight)
                    
                    // Spacing between session dropdown and T/H/S buttons
                    Spacer()
                        .frame(width: 8)
                    
                    // Capsule group: T/H/S buttons (center)
                    HStack(spacing: tabSpacing) {
                        TabButton(label: "⏱️", tab: .timing, selectedTab: $selectedTab)
                        TabButton(label: "📚", tab: .history, selectedTab: $selectedTab)
                        TabButton(label: "⚙️", tab: .settings, selectedTab: $selectedTab)
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
                    
                    // Spacing between T/H/S buttons and Bluetooth button
                    Spacer()
                        .frame(width: 8)

                    // Capsule group: Bluetooth + X buttons (right)
                    HStack(spacing: btSpacing) {
                        Button(action: {
                            NotificationCenter.default.post(name: .init("SessionDropdownShouldClose"), object: nil)
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
                            Button(action: { 
                                NotificationCenter.default.post(name: .init("SessionDropdownShouldClose"), object: nil)
                                disconnectFromCube() 
                            }) {
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
    @ObservedObject var historyManager: HistoryManager
    @Binding var timerState: TimerState
    @Binding var isCubeConfirmed: Bool
    let moveOutput: String
    @Binding var isSessionDropdownExpanded: Bool
    @Binding var isConfirmationWindowShowing: Bool
    @State private var readyWorkItem: DispatchWorkItem?
    @State private var isPreInspectionHolding: Bool = false
    @State private var suppressNextSpaceKeyUp: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Top scramble with session dropdown
            VStack(spacing: 16) {
                // Session dropdown
                HStack {
                    SessionDropdownView(historyManager: historyManager, onExpansionChange: { isExpanded in
                        isSessionDropdownExpanded = isExpanded
                    })
                        .frame(maxWidth: 200)
                    Spacer()
                }
                .padding(.horizontal)
                
                CubeScrambleView(scramble: timerVM.currentScramble)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 200)
            .padding(.horizontal)
            .padding(.top, 20)
            .opacity(timerState == .running ? 0 : 1)

            // Timer text with Ao5 and Ao12
            HStack(spacing: 40) {
                // Ao5 on the left - hidden when timer is running
                if timerState != .running {
                    VStack(spacing: 4) {
                        Text("Ao5")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formatAverage(historyManager.currentSession?.averageOf5()))
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(getAverageColor(historyManager.currentSession?.averageOf5()))
                    }
                    .frame(width: 80)
                } else {
                    // Spacer to maintain layout when Ao5 is hidden
                    Spacer()
                        .frame(width: 80)
                }
                
                // Main timer in the center
            VStack(spacing: 0) {
                let timerText: String = {
                    if timerState == .running { return timerVM.displayTime }
                    if timerVM.isInspecting {
                        switch timerVM.inspectionPenalty {
                        case .none:
                            return "\(max(timerVM.inspectionSecondsRemaining, 0))"
                        case .plus2:
                            return "+2"
                        case .dnf:
                            return "DNF"
                        }
                    }
                    return timerVM.displayTime
                }()

                Text(timerText)
                    .foregroundColor(
                        timerState == .armed ? .red :
                        timerState == .ready ? .green :
                        (isPreInspectionHolding && timerState == .idle ? .blue : .white)
                    )
                    .font(.system(size: timerState == .running ? 90 : 72, weight: .light, design: .monospaced))
                }
                
                // Ao12 on the right - hidden when timer is running
                if timerState != .running {
                    VStack(spacing: 4) {
                        Text("Ao12")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formatAverage(historyManager.currentSession?.averageOf12()))
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(getAverageColor(historyManager.currentSession?.averageOf12()))
                    }
                    .frame(width: 80)
                } else {
                    // Spacer to maintain layout when Ao12 is hidden
                    Spacer()
                        .frame(width: 80)
                }
            }
            .padding(.top, 100)
            .padding(.bottom, 40)

            // Cube3DView visual only, no Bluetooth UI
            ZStack(alignment: .bottom) {
                Cube3DView(isTimerRunning: timerState == .running, isCubeConfirmed: isCubeConfirmed, moveOutput: moveOutput, disableInteraction: isSessionDropdownExpanded || isConfirmationWindowShowing)
                    .frame(width: 2560, height: 600)
                    .offset(y: -40)
                    .opacity(timerState == .running ? 0 : 1)
            }
            .frame(height: 500)
        }
        .frame(minWidth: 600, minHeight: 800)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .overlay(
            // Result confirmation overlay
            Group {
                if timerVM.showingResultConfirmation, let solve = timerVM.completedSolve {
                    ResultConfirmationView(
                        solve: solve,
                        onConfirm: { penalty, comment, scramble in
                            timerVM.confirmSolve(penalty: penalty, comment: comment, scramble: scramble)
                            isConfirmationWindowShowing = false
                        },
                        onCancel: {
                            timerVM.cancelSolve()
                            isConfirmationWindowShowing = false
                        },
                        onDelete: {
                            timerVM.cancelSolve() // Delete the current solve (don't save it)
                            isConfirmationWindowShowing = false
                        }
                    )
                    .onAppear {
                        isConfirmationWindowShowing = true
                    }
                    .onDisappear {
                        isConfirmationWindowShowing = false
                    }
                }
            }
        )
        .onAppear {
            // Connect timer to history manager
            timerVM.setHistoryManager(historyManager)
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
                // Check if we're in an input field - if so, let the event pass through
                if NSApp.keyWindow?.firstResponder is NSTextView || NSApp.keyWindow?.firstResponder is NSTextField {
                    return event
                }
                
                // 如果ResultConfirmationView正在显示，让事件完全通过，不处理任何键盘事件
                if timerVM.showingResultConfirmation {
                    return event
                }
                
                // 如果SessionDropdownView展开，让事件通过
                if isSessionDropdownExpanded {
                    return event
                }
                
                // Handle ESC key to close session dropdown or cancel countdown
                if event.keyCode == 53 { // ESC key
                    NotificationCenter.default.post(name: .init("SessionDropdownShouldClose"), object: nil)
                    
                    // Cancel countdown and reset to idle state
                    if timerState == .inspecting || timerState == .armed || timerState == .ready {
                        timerVM.cancelInspection()
                        timerState = .idle
                        isPreInspectionHolding = false
                        readyWorkItem?.cancel()
                        suppressNextSpaceKeyUp = false
                    }
                    
                    return nil
                }
                if event.keyCode == 49 {
                    switch event.type {
                    case .keyDown:
                        if timerState == .idle {
                            // Close session dropdown if open, then start inspection
                            NotificationCenter.default.post(name: .init("SessionDropdownShouldClose"), object: nil)
                            // Mark pre-inspection hold to show blue
                            isPreInspectionHolding = true
                        } else if timerState == .inspecting {
                            // During inspection: hold to arm then ready after 0.3s
                            if timerState != .armed && timerState != .ready {
                                timerState = .armed
                                let work = DispatchWorkItem {
                                    if timerState == .armed {
                                        timerState = .ready
                                    }
                                }
                                readyWorkItem = work
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
                            }
                        } else if timerState == .running {
                            timerVM.toggleTimer()
                            timerState = .idle
                            readyWorkItem?.cancel()
                            // Prevent the immediate space key-up from starting a new inspection
                            suppressNextSpaceKeyUp = true
                        }
                    case .keyUp:
                        if timerState == .idle {
                            // If we just stopped a solve, ignore the first space key-up
                            if suppressNextSpaceKeyUp {
                                suppressNextSpaceKeyUp = false
                                isPreInspectionHolding = false
                                break
                            }
                            // Start inspection on first release
                            timerVM.startInspection()
                            timerState = .inspecting
                            isPreInspectionHolding = false
                        } else if timerState == .armed {
                            // Released too early during inspection hold
                            readyWorkItem?.cancel()
                            timerState = .inspecting
                        } else if timerState == .ready {
                            // Start timer on release
                            timerState = .running
                            timerVM.cancelInspection()
                            timerVM.toggleTimer()
                            // Note: timer continues regardless of inspection penalty
                        } else if timerState == .inspecting {
                            // If user taps space quickly during inspection without holding, keep inspecting
                            // No state change
                        }
                    default: break
                    }
                    return nil
                }
                if timerState == .running && event.type == .keyDown {
                    timerVM.toggleTimer()
                    timerState = .idle
                    isPreInspectionHolding = false
                    readyWorkItem?.cancel()
                    // Stopped by a non-space key; still ignore the next space key-up
                    suppressNextSpaceKeyUp = true
                    return nil
                }
                return event
            }
        }
        .onReceive(timerVM.$isInspecting) { inspecting in
            if !inspecting && timerState == .inspecting {
                timerState = .idle
            }
        }
    }
    
    private func formatAverage(_ average: Double?) -> String {
        guard let avg = average else { return "-" }
        
        // Special case for DNF average
        if avg == -1 {
            return "DNF"
        }
        
        if avg >= 60 {
            let minutes = Int(avg) / 60
            let seconds = avg.truncatingRemainder(dividingBy: 60)
            return String(format: "%d:%.3f", minutes, seconds)
        } else {
            return String(format: "%.3f", avg)
        }
    }
    
    private func getAverageColor(_ average: Double?) -> Color {
        guard let avg = average else { return .white }
        
        // DNF average is red
        if avg == -1 {
            return .red
        }
        
        // Normal average is white
        return .white
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
                Text("GAN Smart Cubes")
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
                    Text("Scanning for GAN Smart Cubes...")
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            if bluetoothManager.discoveredDevices.isEmpty && !bluetoothManager.isScanning {
                Text("No GAN Cubes found")
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
