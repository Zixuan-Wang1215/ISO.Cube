import SwiftUI
import Combine

class TimerViewModel: ObservableObject {
    @Published var displayTime = "0:00.00"
    @Published var currentScramble = ScrambleModel.generateScramble()

    private var timer: AnyCancellable?
    private var startDate: Date?
    private var isTiming = false

    func toggleTimer() {
        if isTiming {
            stopTimer()
        } else {
            startTimer()
        }
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
        currentScramble = ScrambleModel.generateScramble()
        // save results
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let centiseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, centiseconds)
        } else if isTiming{
            return String(format: "%d.%02d", seconds, centiseconds)
        } else {
            print("not timing")
            return String(format: "%d.%03d", seconds, centiseconds)
        }
        
    }
}
