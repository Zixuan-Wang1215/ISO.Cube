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
                
                Button(LocalizationKey.done.localized) {
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
                    Text(historyManager.currentSession?.name ?? LocalizationKey.noSession.localized)
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
                        Text(LocalizationKey.noSolvesYet.localized)
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
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingLanguagePicker = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text(LocalizationKey.settings.localized)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("ISO.Cube")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Settings Content
                VStack(spacing: 24) {
                    // Language Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(LocalizationKey.language.localized)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        // Current Language Display
                        Button(action: {
                            showingLanguagePicker.toggle()
                        }) {
                            HStack {
                                Text(localizationManager.currentLanguage.flag)
                                    .font(.system(size: 24))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(localizationManager.currentLanguage.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text(LocalizationKey.selectLanguage.localized)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Language Options
                        if showingLanguagePicker {
                            VStack(spacing: 8) {
                                ForEach(Language.allCases, id: \.self) { language in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            localizationManager.currentLanguage = language
                                            showingLanguagePicker = false
                                        }
                                    }) {
                                        HStack {
                                            Text(language.flag)
                                                .font(.system(size: 20))
                                            
                                            Text(language.displayName)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            if localizationManager.currentLanguage == language {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(localizationManager.currentLanguage == language ? 
                                                      Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(localizationManager.currentLanguage == language ? 
                                                               Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    // App Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("App Info")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            InfoRow(title: "Version", value: "1.0.0")
                            InfoRow(title: "Developer", value: "ISO.Hi")
                            InfoRow(title: "Platform", value: "macOS")
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            // Refresh the view when language changes
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
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
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingDevicePicker = false
    @State private var pythonProcess: Process? = nil
    @State private var isConnectedToCube = false
    @State private var moveOutput = ""
    @State private var isCubeConfirmed = false
    @State private var cubeSolution = ""
    @State private var cubeState = ""
    @State private var cubeName = ""
    @State private var cubeBattery = ""
    @State private var showingDebugWindow = false
    @State private var hasExecutedInitialSolution = false
    @State private var isSessionDropdownExpanded = false
    @State private var isConfirmationWindowShowing = false
    @State private var hasTriggeredSwipe = false
    @State private var currentScramble = ""
    @State private var shouldAutoStartInspection = false
    @State private var shouldAutoStartTimer = false
    @State private var shouldAutoStopTimer = false
    @State private var hasStartedSolving = false

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
                    TimerView(historyManager: historyManager, timerState: $timerState, isCubeConfirmed: $isCubeConfirmed, moveOutput: moveOutput, cubeSolution: cubeSolution, hasExecutedInitialSolution: hasExecutedInitialSolution, isSessionDropdownExpanded: $isSessionDropdownExpanded, isConfirmationWindowShowing: $isConfirmationWindowShowing, currentScramble: $currentScramble, shouldAutoStartInspection: $shouldAutoStartInspection, shouldAutoStartTimer: $shouldAutoStartTimer, shouldAutoStopTimer: $shouldAutoStopTimer, hasStartedSolving: $hasStartedSolving)
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

                    // Capsule group: Bluetooth + Debug + X buttons (right)
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
                                showingDebugWindow = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 7)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
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

                // Python output window removed - output is still processed for connection confirmation
            }
        }
        .sheet(isPresented: $showingDevicePicker) {
            DevicePickerView(bluetoothManager: bluetoothManager) { device in
                connectToDevice(device)
                showingDevicePicker = false
            }
        }
        .sheet(isPresented: $showingDebugWindow) {
            DebugWindowView(
                cubeName: cubeName, 
                cubeBattery: cubeBattery, 
                cubeState: cubeState, 
                cubeSolution: cubeSolution,
                moveOutput: moveOutput,
                isCubeConfirmed: isCubeConfirmed,
                hasExecutedInitialSolution: hasExecutedInitialSolution,
                currentScramble: currentScramble
            )
        }
    }

    // MARK: - Python Connection
    private func connectToDevice(_ device: CBPeripheral) {
        pythonProcess?.terminate()
        pythonProcess = nil

        // 获取UUID和MAC地址
        let uuidAddress = device.identifier.uuidString
        let macAddress = bluetoothManager.getMacAddress(for: device)

        let pythonPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".pyenv/versions/3.12.3/bin/python").path
        let scriptPath = "/Users/iso.hi/Documents/Code/ISO.Cube/test_raw_data.py"

        let task = Process()
        task.executableURL = URL(fileURLWithPath: pythonPath)
        task.arguments = [scriptPath, uuidAddress, macAddress]  // 传递两个参数

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
                    // 检查是否是魔方解的消息
                    if chunk.contains("CUBE_SOLUTION:") {
                        self.handleCubeSolution(chunk)
                    }
                    // 检查是否是魔方状态的消息
                    if chunk.contains("State:") {
                        self.handleCubeState(chunk)
                    }
                    // 检查是否是电量信息
                    if chunk.contains("Battery:") {
                        self.handleCubeBattery(chunk)
                    }
                    // 检查是否是魔方移动信息
                    if chunk.contains("Move:") {
                        self.handleCubeMove(chunk)
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
            cubeName = device.name ?? "Unknown Device"
            moveOutput = "Connecting to \(cubeName)...\n"
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
        cubeSolution = ""
        cubeState = ""
        cubeName = ""
        cubeBattery = ""
        hasExecutedInitialSolution = false
    }
    
    private func handleCubeConnectedConfirmation() {
        isCubeConfirmed = true
    }
    
    private func handleCubeSolution(_ chunk: String) {
        // 提取解的内容
        if let solutionStart = chunk.range(of: "CUBE_SOLUTION: ") {
            let solution = String(chunk[solutionStart.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            cubeSolution = solution
        }
    }
    
    private func handleCubeState(_ chunk: String) {
        // 提取状态的内容
        if let stateStart = chunk.range(of: "State: ") {
            let state = String(chunk[stateStart.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            cubeState = state
            
            // 检查魔方状态是否与打乱状态匹配
            checkAndStartInspectionIfMatched(cubeState: state)
        }
    }
    
    private func handleCubeBattery(_ chunk: String) {
        // 提取电量的内容
        if let batteryStart = chunk.range(of: "Battery: ") {
            let battery = String(chunk[batteryStart.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            cubeBattery = battery
        }
    }
    
    private func handleCubeMove(_ chunk: String) {
        // 提取移动的内容
        if let moveStart = chunk.range(of: "Move: ") {
            _ = String(chunk[moveStart.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 如果正在倒计时中且还没有开始解题，设置开始计时的标志
            if timerState == .inspecting && !hasStartedSolving {
                DispatchQueue.main.async {
                    self.hasStartedSolving = true
                    self.shouldAutoStartTimer = true
                }
            }
        }
    }
    
    private func checkAndStartInspectionIfMatched(cubeState: String) {
        // 检查是否应该开始倒计时（空闲状态）
        if isCubeConfirmed && timerState == .idle {
            // 获取当前打乱公式的展开状态
            let cubeNetView = CubeNetView(scramble: currentScramble)
            let expectedScrambledState = cubeNetView.getCubeStateString()
            
            // 比较魔方状态和打乱状态
            if cubeState == expectedScrambledState {
                // 状态匹配，设置自动开始倒计时的标志
                DispatchQueue.main.async {
                    self.shouldAutoStartInspection = true
                }
            }
        }
        
        // 检查是否应该结束计时（正在计时中）
        if isCubeConfirmed && timerState == .running && hasStartedSolving {
            // 检查魔方是否已复原（所有面都是相同颜色）
            let solvedState = "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB"
            if cubeState == solvedState {
                // 魔方已复原，设置结束计时的标志
                DispatchQueue.main.async {
                    self.shouldAutoStopTimer = true
                }
            }
        }
    }
}

// MARK: - TimerView
struct TimerView: View {
    @StateObject private var timerVM = TimerViewModel()
    @ObservedObject var historyManager: HistoryManager
    @Binding var timerState: TimerState
    @Binding var isCubeConfirmed: Bool
    let moveOutput: String
    let cubeSolution: String
    let hasExecutedInitialSolution: Bool
    @Binding var isSessionDropdownExpanded: Bool
    @Binding var isConfirmationWindowShowing: Bool
    @Binding var currentScramble: String
    @Binding var shouldAutoStartInspection: Bool
    @Binding var shouldAutoStartTimer: Bool
    @Binding var shouldAutoStopTimer: Bool
    @Binding var hasStartedSolving: Bool
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
                
                CubeScrambleView(scramble: $timerVM.currentScramble)
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
                Cube3DView(isTimerRunning: timerState == .running, isCubeConfirmed: isCubeConfirmed, moveOutput: moveOutput, cubeSolution: cubeSolution, hasExecutedInitialSolution: hasExecutedInitialSolution, disableInteraction: isSessionDropdownExpanded || isConfirmationWindowShowing, forceFullOpacity: false)
                    .frame(width: 2560, height: 600)
                    .offset(y: -40)
                    .opacity((timerState == .running && !isCubeConfirmed) ? 0 : 1)
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
            // Initialize currentScramble with the initial value
            currentScramble = timerVM.currentScramble
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
                
                // Handle ESC key to close session dropdown, cancel countdown, or stop timer
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
                    // Cancel timer if running (no confirmation dialog)
                    else if timerState == .running {
                        timerVM.cancelTimer()
                        timerState = .idle
                        hasStartedSolving = false
                    }
                    
                    return nil
                }
                if event.keyCode == 49 {
                    // 如果魔方已连接，禁用空格键开始倒计时/计时功能
                    if isCubeConfirmed {
                        return event // 让事件通过，不处理空格键
                    }
                    
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
                            // Don't suppress the next space key-up to allow immediate next inspection
                            suppressNextSpaceKeyUp = false
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
                    // Don't suppress the next space key-up to allow immediate next inspection
                    suppressNextSpaceKeyUp = false
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
        .onChange(of: timerVM.currentScramble) { _, newValue in
            currentScramble = newValue
        }
        .onChange(of: shouldAutoStartInspection) { _, newValue in
            if newValue && timerState == .idle {
                // 自动开始15秒倒计时
                timerVM.startInspection()
                timerState = .inspecting
                // 重置标志和解题状态
                shouldAutoStartInspection = false
                hasStartedSolving = false
            }
        }
        .onChange(of: shouldAutoStartTimer) { _, newValue in
            if newValue && timerState == .inspecting {
                // 自动开始计时
                timerVM.cancelInspection()
                timerVM.toggleTimer()
                timerState = .running
                // 重置标志
                shouldAutoStartTimer = false
            }
        }
        .onChange(of: shouldAutoStopTimer) { _, newValue in
            if newValue && timerState == .running {
                // 自动结束计时
                timerVM.toggleTimer()
                timerState = .idle
                hasStartedSolving = false
                // 重置标志
                shouldAutoStopTimer = false
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
    private var deviceMacAddresses: [UUID: String] = [:]

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
            // 获取MAC地址
            var macAddress = peripheral.identifier.uuidString
            if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                let array = [UInt8](data)
                if array.count >= 6 {
                    macAddress = array.reversed()[0..<6]
                        .map { String(format: "%02X", $0) }
                        .joined(separator: ":")
                }
            }
            
            DispatchQueue.main.async {
                if !self.discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                    // 存储MAC地址到字典中
                    self.deviceMacAddresses[peripheral.identifier] = macAddress
                    self.discoveredDevices.append(peripheral)
                }
            }
        }
    }
    
    func getMacAddress(for peripheral: CBPeripheral) -> String {
        return deviceMacAddresses[peripheral.identifier] ?? peripheral.identifier.uuidString
    }
}

// MARK: - Debug Window
struct DebugWindowView: View {
    let cubeName: String
    let cubeBattery: String
    let cubeState: String
    let cubeSolution: String
    let moveOutput: String
    let isCubeConfirmed: Bool
    let hasExecutedInitialSolution: Bool
    let currentScramble: String
    @Environment(\.dismiss) private var dismiss
    
    // 生成展开state
    private func getExpandedState() -> String {
        // 使用传入的当前打乱公式计算展开状态
        if !currentScramble.isEmpty {
            let cubeNetView = CubeNetView(scramble: currentScramble)
            return cubeNetView.getCubeStateString()
        }
        
        // 如果没有打乱公式，返回复原状态
        return "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(LocalizationKey.cubeInfo.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(LocalizationKey.done.localized) {
                    dismiss()
                }
            }
            .padding()
            
            // 信息显示区域
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKey.deviceName.localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(cubeName.isEmpty ? LocalizationKey.notConnected.localized : cubeName)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKey.batteryLevel.localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        batteryIcon(for: cubeBattery)
                        Text(cubeBattery.isEmpty ? LocalizationKey.unknown.localized : cubeBattery)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKey.expandedState.localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(getExpandedState())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .lineLimit(2)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKey.realtimeState.localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(cubeState.isEmpty ? LocalizationKey.noStateData.localized : cubeState)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 500, height: 400)
    }
    
    // 电池图标函数
    private func batteryIcon(for battery: String) -> some View {
        let batteryLevel = extractBatteryLevel(from: battery)
        
        return Image(systemName: batteryIconName(for: batteryLevel))
            .font(.system(size: 20))
            .foregroundColor(batteryColor(for: batteryLevel))
    }
    
    private func extractBatteryLevel(from battery: String) -> Int {
        // 从 "85%" 中提取数字
        let cleaned = battery.replacingOccurrences(of: "%", with: "")
        return Int(cleaned) ?? 0
    }
    
    private func batteryIconName(for level: Int) -> String {
        switch level {
        case 0:
            return "battery.0percent"
        case 1...25:
            return "battery.25percent"
        case 26...50:
            return "battery.50percent"
        case 51...75:
            return "battery.75percent"
        case 76...100:
            return "battery.100percent"
        default:
            return "battery.0percent"
        }
    }
    
    private func batteryColor(for level: Int) -> Color {
        switch level {
        case 0...20:
            return .red
        case 21...50:
            return .orange
        case 51...100:
            return .green
        default:
            return .gray
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
                Text(LocalizationKey.ganSmartCubes.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(LocalizationKey.done.localized) {
                    bluetoothManager.stopScanning()
                    dismiss()
                }
            }
            .padding()

            if bluetoothManager.isScanning {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text(LocalizationKey.scanningForCubes.localized)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            if bluetoothManager.discoveredDevices.isEmpty && !bluetoothManager.isScanning {
                Text(LocalizationKey.noCubesFound.localized)
                    .foregroundColor(.secondary)
                    .padding()
            }

            List(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                Button(action: { onDeviceSelected(device) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name ?? LocalizationKey.unknownDevice.localized)
                            .font(.headline)
                        Text("MAC: \(bluetoothManager.getMacAddress(for: device))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("ID: \(device.identifier.uuidString)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }

            HStack {
                Button(LocalizationKey.refresh.localized) { bluetoothManager.startScanning() }
                    .disabled(bluetoothManager.isScanning)
                Spacer()
                Button(LocalizationKey.stopScanning.localized) { bluetoothManager.stopScanning() }
                    .disabled(!bluetoothManager.isScanning)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .onDisappear { bluetoothManager.stopScanning() }
    }
}
