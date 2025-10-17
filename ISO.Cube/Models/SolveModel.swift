import Foundation

struct SolveModel: Codable, Identifiable {
    var id = UUID()
    let penalty: Int // 0=none, 2000=plus2, -1=DNF
    let time: Int // milliseconds
    let scramble: String
    let comment: String
    let timestamp: Int // Unix timestamp
    
    init(penalty: Int = 0, time: Int, scramble: String, comment: String = "", timestamp: Int = Int(Date().timeIntervalSince1970)) {
        self.penalty = penalty
        self.time = time
        self.scramble = scramble
        self.comment = comment
        self.timestamp = timestamp
    }
    
    // Convert to csTimer format array
    func toCsTimerFormat() -> [Any] {
        return [penalty, time, scramble, comment, timestamp]
    }
    
    // Create from csTimer format array
    static func fromCsTimerFormat(_ array: [Any]) -> SolveModel? {
        guard array.count >= 5,
              let penalty = array[0] as? Int,
              let time = array[1] as? Int,
              let scramble = array[2] as? String,
              let comment = array[3] as? String,
              let timestamp = array[4] as? Int else {
            return nil
        }
        return SolveModel(penalty: penalty, time: time, scramble: scramble, comment: comment, timestamp: timestamp)
    }
    
    // Computed properties for display
    var displayTime: String {
        let seconds = Double(time) / 1000.0
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        let milliseconds = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%03d", minutes, remainingSeconds, milliseconds)
        } else {
            return String(format: "%d.%03d", remainingSeconds, milliseconds)
        }
    }
    
    var penaltyText: String {
        switch penalty {
        case -1: return "DNF"
        case 2000: return "+2"
        default: return ""
        }
    }
    
    var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
