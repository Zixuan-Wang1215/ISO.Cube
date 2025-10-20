import SwiftUI
import Combine

class TimerViewModel: ObservableObject {
    @Published var displayTime = "0:00.00"
    @Published var currentScramble = ScrambleModel.generateScramble()
    @Published var inspectionSecondsRemaining: Int = 15
    @Published var isInspecting: Bool = false
    enum InspectionPenalty { case none, plus2, dnf }
    @Published var inspectionPenalty: InspectionPenalty = .none
    @Published var showingResultConfirmation = false
    @Published var completedSolve: SolveModel?

    private var timer: AnyCancellable?
    private var inspectionTimer: AnyCancellable?
    private var startDate: Date?
    private var isTiming = false
    private var historyManager: HistoryManager?

    func toggleTimer() {
        if isTiming {
            stopTimer()
        } else {
            startTimer()
        }
    }

    func startInspection() {
        isInspecting = true
        inspectionSecondsRemaining = 15
        inspectionPenalty = .none
        inspectionTimer?.cancel()
        inspectionTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.inspectionSecondsRemaining -= 1
                // Apply penalties when past 15s
                if self.inspectionSecondsRemaining <= -3 {
                    self.inspectionPenalty = .dnf
                } else if self.inspectionSecondsRemaining <= -1 {
                    self.inspectionPenalty = .plus2
                } else {
                    self.inspectionPenalty = .none
                }
            }
    }

    func cancelInspection() {
        inspectionTimer?.cancel()
        inspectionTimer = nil
        isInspecting = false
        inspectionSecondsRemaining = 15
    }
    
    func cancelTimer() {
        timer?.cancel()
        timer = nil
        isTiming = false
        startDate = nil
        // Don't create completed solve or show confirmation
        currentScramble = ScrambleModel.generateScramble()
        inspectionPenalty = .none
    }

    private func startTimer() {
        startDate = Date()
        isTiming = true

        timer = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let start = self.startDate else { return }
                let elapsed = Date().timeIntervalSince(start)
                self.displayTime = self.formatTime(elapsed)
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
        isTiming = false
        
        // Create completed solve
        if let startDate = startDate {
            let elapsedTime = Date().timeIntervalSince(startDate)
            let timeInMilliseconds = Int(elapsedTime * 1000)
            
            let solve = SolveModel(
                penalty: 0, // Will be set by user in confirmation
                time: timeInMilliseconds,
                scramble: currentScramble,
                comment: "",
                timestamp: Int(Date().timeIntervalSince1970)
            )
            
            completedSolve = solve
            showingResultConfirmation = true
        }
        
        currentScramble = ScrambleModel.generateScramble()
        inspectionPenalty = .none
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 1000)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
        } else {
            return String(format: "%d.%03d", seconds, milliseconds)
        }
    }
    
    // MARK: - History Integration
    
    func setHistoryManager(_ manager: HistoryManager) {
        self.historyManager = manager
    }
    
    func confirmSolve(penalty: Int, comment: String, scramble: String) {
        guard let solve = completedSolve else { return }
        
        // Update solve with penalty, comment, and scramble
        let updatedSolve = SolveModel(
            penalty: penalty,
            time: solve.time,
            scramble: scramble,
            comment: comment,
            timestamp: solve.timestamp
        )
        
        // Save to history
        historyManager?.addSolve(updatedSolve)
        
        // Reset state
        showingResultConfirmation = false
        completedSolve = nil
    }
    
    func cancelSolve() {
        showingResultConfirmation = false
        completedSolve = nil
    }
}
