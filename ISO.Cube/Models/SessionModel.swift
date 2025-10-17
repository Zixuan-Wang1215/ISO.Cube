import Foundation

struct SessionModel: Codable, Identifiable {
    let id: String
    var name: String
    var solves: [SolveModel]
    let createdAt: Int // Unix timestamp
    
    init(id: String = UUID().uuidString, name: String, solves: [SolveModel] = [], createdAt: Int = Int(Date().timeIntervalSince1970)) {
        self.id = id
        self.name = name
        self.solves = solves
        self.createdAt = createdAt
    }
    
    // Computed properties for statistics
    var solveCount: Int {
        return solves.count
    }
    
    var bestTime: Int? {
        let validSolves = solves.filter { $0.penalty != -1 } // Exclude DNFs
        return validSolves.map { $0.time + $0.penalty }.min()
    }
    
    var averageTime: Double? {
        let validSolves = solves.filter { $0.penalty != -1 } // Exclude DNFs
        guard !validSolves.isEmpty else { return nil }
        let totalTime = validSolves.reduce(0) { $0 + $1.time + $1.penalty }
        return Double(totalTime) / Double(validSolves.count) / 1000.0 // Convert to seconds
    }
    
    var dnfCount: Int {
        return solves.filter { $0.penalty == -1 }.count
    }
    
    var plus2Count: Int {
        return solves.filter { $0.penalty == 2000 }.count
    }
    
    // Add a solve to this session
    mutating func addSolve(_ solve: SolveModel) {
        solves.append(solve)
    }
    
    // Remove a solve by ID
    mutating func removeSolve(withId id: UUID) {
        solves.removeAll { $0.id == id }
    }
    
    // Get recent solves (last N solves)
    func recentSolves(count: Int = 5) -> [SolveModel] {
        return Array(solves.suffix(count))
    }
    
    // Get best solves
    func bestSolves(count: Int = 5) -> [SolveModel] {
        let validSolves = solves.filter { $0.penalty != -1 }
        return validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }.prefix(count).map { $0 }
    }
    
    // MARK: - Advanced Statistics
    
    // Calculate average of N consecutive solves (Ao5, Ao12)
    func averageOf(count: Int) -> Double? {
        guard solves.count >= count else { return nil }
        
        // Get the most recent N solves
        let recentSolves = Array(solves.suffix(count))
        let validSolves = recentSolves.filter { $0.penalty != -1 }
        let dnfCount = recentSolves.count - validSolves.count
        
        // If more than 1 DNF, cannot calculate average
        if dnfCount > 1 {
            return -1 // Special value indicating DNF average
        }
        
        // If exactly 1 DNF, DNF counts as worst, only trim best
        if dnfCount == 1 {
            guard validSolves.count >= 2 else { return -1 } // Need at least 2 valid solves
            
            let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
            let trimmedSolves = Array(sortedSolves.dropFirst()) // Remove only best, DNF is worst
            
            guard !trimmedSolves.isEmpty else { return -1 }
            
            let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
            return Double(totalTime) / Double(trimmedSolves.count) / 1000.0
        }
        
        // No DNFs, trim best and worst
        if validSolves.count >= 3 {
            let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
            let trimmedSolves = Array(sortedSolves.dropFirst().dropLast()) // Remove best and worst
            
            guard !trimmedSolves.isEmpty else { return -1 }
            
            let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
            return Double(totalTime) / Double(trimmedSolves.count) / 1000.0
        } else {
            // Not enough valid solves
            return -1
        }
    }
    
    // Calculate average of N consecutive solves with trimming (for Ao50, Ao100)
    func trimmedAverageOf(count: Int, trimPercent: Double = 0.05) -> Double? {
        guard solves.count >= count else { return nil }
        
        // Get the most recent N solves
        let recentSolves = Array(solves.suffix(count))
        let validSolves = recentSolves.filter { $0.penalty != -1 }
        let dnfCount = recentSolves.count - validSolves.count
        
        // Determine if DNF count is negligible (less than 10% of total)
        let dnfPercentage = Double(dnfCount) / Double(count)
        if dnfPercentage > 0.1 { // More than 10% DNF
            return -1 // Special value indicating DNF average
        }
        
        // DNF count is negligible, remove DNFs and then trim
        let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
        
        // Calculate trim count based on original count (5% of original count)
        let trimCount = Int(Double(count) * trimPercent)
        
        // Ensure we have enough solves after trimming
        guard sortedSolves.count > trimCount * 2 else { return -1 }
        
        let trimmedSolves = Array(sortedSolves.dropFirst(trimCount).dropLast(trimCount))
        
        guard !trimmedSolves.isEmpty else { return -1 }
        
        let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
        return Double(totalTime) / Double(trimmedSolves.count) / 1000.0
    }
    
    // Calculate Mo3 (mean of 3) - no trimming, just average of 3 consecutive solves
    func meanOf3() -> Double? {
        guard solves.count >= 3 else { return nil }
        
        // Get the most recent 3 solves
        let recentSolves = Array(solves.suffix(3))
        let validSolves = recentSolves.filter { $0.penalty != -1 }
        let dnfCount = recentSolves.count - validSolves.count
        
        // If more than 1 DNF, cannot calculate average
        if dnfCount > 1 {
            return -1 // Special value indicating DNF average
        }
        
        // If exactly 1 DNF, return DNF
        if dnfCount == 1 {
            return -1
        }
        
        // No DNFs, calculate simple average
        guard !validSolves.isEmpty else { return -1 }
        
        let totalTime = validSolves.reduce(0) { $0 + $1.time + $1.penalty }
        return Double(totalTime) / Double(validSolves.count) / 1000.0
    }
    
    // Calculate Ao5 (average of 5)
    func averageOf5() -> Double? {
        return averageOf(count: 5)
    }
    
    // Calculate Ao12 (average of 12)
    func averageOf12() -> Double? {
        return averageOf(count: 12)
    }
    
    // Calculate Ao50 (average of 50, trimmed)
    func averageOf50() -> Double? {
        return trimmedAverageOf(count: 50)
    }
    
    // Calculate Ao100 (average of 100, trimmed)
    func averageOf100() -> Double? {
        return trimmedAverageOf(count: 100)
    }
    
    // MARK: - Best Times
    
    // Calculate best Mo3 (mean of 3) from all possible consecutive 3-solve groups - no trimming
    func bestMeanOf3() -> Double? {
        guard solves.count >= 3 else { return nil }
        
        var bestAverage: Double? = nil
        
        for i in 0...(solves.count - 3) {
            let groupSolves = Array(solves[i..<i+3])
            let validSolves = groupSolves.filter { $0.penalty != -1 }
            let dnfCount = groupSolves.count - validSolves.count
            
            // Skip groups with more than 1 DNF
            if dnfCount > 1 { continue }
            
            // If exactly 1 DNF, skip this group
            if dnfCount == 1 { continue }
            
            // No DNFs: calculate simple average
            guard validSolves.count == 3 else { continue }
            
            let totalTime = validSolves.reduce(0) { $0 + $1.time + $1.penalty }
            let average = Double(totalTime) / Double(validSolves.count) / 1000.0
            
            if bestAverage == nil || average < bestAverage! {
                bestAverage = average
            }
        }
        
        return bestAverage
    }
    
    // Calculate best Ao5 from all possible consecutive 5-solve groups
    func bestAverageOf5() -> Double? {
        guard solves.count >= 5 else { return nil }
        
        var bestAverage: Double? = nil
        
        for i in 0...(solves.count - 5) {
            let groupSolves = Array(solves[i..<i+5])
            let validSolves = groupSolves.filter { $0.penalty != -1 }
            let dnfCount = groupSolves.count - validSolves.count
            
            // Skip groups with more than 1 DNF
            if dnfCount > 1 { continue }
            
            // Calculate average for this group
            if dnfCount == 1 {
                // 1 DNF: only trim best
                guard validSolves.count >= 2 else { continue }
                let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
                let trimmedSolves = Array(sortedSolves.dropFirst())
                guard !trimmedSolves.isEmpty else { continue }
                let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
                let average = Double(totalTime) / Double(trimmedSolves.count) / 1000.0
                if bestAverage == nil || average < bestAverage! {
                    bestAverage = average
                }
            } else {
                // No DNFs: trim best and worst
                guard validSolves.count >= 3 else { continue }
                let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
                let trimmedSolves = Array(sortedSolves.dropFirst().dropLast())
                guard !trimmedSolves.isEmpty else { continue }
                let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
                let average = Double(totalTime) / Double(trimmedSolves.count) / 1000.0
                if bestAverage == nil || average < bestAverage! {
                    bestAverage = average
                }
            }
        }
        
        return bestAverage
    }
    
    // Calculate best Ao12 from all possible consecutive 12-solve groups
    func bestAverageOf12() -> Double? {
        guard solves.count >= 12 else { return nil }
        
        var bestAverage: Double? = nil
        
        for i in 0...(solves.count - 12) {
            let groupSolves = Array(solves[i..<i+12])
            let validSolves = groupSolves.filter { $0.penalty != -1 }
            let dnfCount = groupSolves.count - validSolves.count
            
            // Skip groups with more than 1 DNF
            if dnfCount > 1 { continue }
            
            // Calculate average for this group
            if dnfCount == 1 {
                // 1 DNF: only trim best
                guard validSolves.count >= 2 else { continue }
                let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
                let trimmedSolves = Array(sortedSolves.dropFirst())
                guard !trimmedSolves.isEmpty else { continue }
                let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
                let average = Double(totalTime) / Double(trimmedSolves.count) / 1000.0
                if bestAverage == nil || average < bestAverage! {
                    bestAverage = average
                }
            } else {
                // No DNFs: trim best and worst
                guard validSolves.count >= 3 else { continue }
                let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
                let trimmedSolves = Array(sortedSolves.dropFirst().dropLast())
                guard !trimmedSolves.isEmpty else { continue }
                let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
                let average = Double(totalTime) / Double(trimmedSolves.count) / 1000.0
                if bestAverage == nil || average < bestAverage! {
                    bestAverage = average
                }
            }
        }
        
        return bestAverage
    }
    
    // MARK: - Get Solve Groups for Averages
    
    // Get the solves used for the current Mo3
    func getCurrentMeanOf3Solves() -> [SolveModel]? {
        guard solves.count >= 3 else { return nil }
        return Array(solves.suffix(3))
    }
    
    // Get the solves used for the current Ao5
    func getCurrentAverageOf5Solves() -> [SolveModel]? {
        guard solves.count >= 5 else { return nil }
        return Array(solves.suffix(5))
    }
    
    // Get the solves used for the current Ao12
    func getCurrentAverageOf12Solves() -> [SolveModel]? {
        guard solves.count >= 12 else { return nil }
        return Array(solves.suffix(12))
    }
    
    // Get the solves used for the current Ao50
    func getCurrentAverageOf50Solves() -> [SolveModel]? {
        guard solves.count >= 50 else { return nil }
        return Array(solves.suffix(50))
    }
    
    // Get the solves used for the current Ao100
    func getCurrentAverageOf100Solves() -> [SolveModel]? {
        guard solves.count >= 100 else { return nil }
        return Array(solves.suffix(100))
    }
    
    // Get the solves used for the best Mo3 - no trimming
    func getBestMeanOf3Solves() -> [SolveModel]? {
        guard solves.count >= 3 else { return nil }
        
        var bestAverage: Double? = nil
        var bestSolves: [SolveModel]? = nil
        
        for i in 0...(solves.count - 3) {
            let groupSolves = Array(solves[i..<i+3])
            let validSolves = groupSolves.filter { $0.penalty != -1 }
            let dnfCount = groupSolves.count - validSolves.count
            
            // Skip groups with more than 1 DNF
            if dnfCount > 1 { continue }
            
            // If exactly 1 DNF, skip this group
            if dnfCount == 1 { continue }
            
            // No DNFs: calculate simple average
            guard validSolves.count == 3 else { continue }
            
            let totalTime = validSolves.reduce(0) { $0 + $1.time + $1.penalty }
            let average = Double(totalTime) / Double(validSolves.count) / 1000.0
            
            if bestAverage == nil || average < bestAverage! {
                bestAverage = average
                bestSolves = groupSolves
            }
        }
        
        return bestSolves
    }
    
    // Get the solves used for the best Ao5
    func getBestAverageOf5Solves() -> [SolveModel]? {
        guard solves.count >= 5 else { return nil }
        
        var bestAverage: Double? = nil
        var bestSolves: [SolveModel]? = nil
        
        for i in 0...(solves.count - 5) {
            let groupSolves = Array(solves[i..<i+5])
            let validSolves = groupSolves.filter { $0.penalty != -1 }
            let dnfCount = groupSolves.count - validSolves.count
            
            if dnfCount > 1 { continue }
            
            let average: Double
            if dnfCount == 1 {
                guard validSolves.count >= 2 else { continue }
                let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
                let trimmedSolves = Array(sortedSolves.dropFirst())
                guard !trimmedSolves.isEmpty else { continue }
                let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
                average = Double(totalTime) / Double(trimmedSolves.count) / 1000.0
            } else {
                guard validSolves.count >= 3 else { continue }
                let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
                let trimmedSolves = Array(sortedSolves.dropFirst().dropLast())
                guard !trimmedSolves.isEmpty else { continue }
                let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
                average = Double(totalTime) / Double(trimmedSolves.count) / 1000.0
            }
            
            if bestAverage == nil || average < bestAverage! {
                bestAverage = average
                bestSolves = groupSolves
            }
        }
        
        return bestSolves
    }
    
    // Get the solves used for the best Ao12
    func getBestAverageOf12Solves() -> [SolveModel]? {
        guard solves.count >= 12 else { return nil }
        
        var bestAverage: Double? = nil
        var bestSolves: [SolveModel]? = nil
        
        for i in 0...(solves.count - 12) {
            let groupSolves = Array(solves[i..<i+12])
            let validSolves = groupSolves.filter { $0.penalty != -1 }
            let dnfCount = groupSolves.count - validSolves.count
            
            if dnfCount > 1 { continue }
            
            let average: Double
            if dnfCount == 1 {
                guard validSolves.count >= 2 else { continue }
                let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
                let trimmedSolves = Array(sortedSolves.dropFirst())
                guard !trimmedSolves.isEmpty else { continue }
                let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
                average = Double(totalTime) / Double(trimmedSolves.count) / 1000.0
            } else {
                guard validSolves.count >= 3 else { continue }
                let sortedSolves = validSolves.sorted { ($0.time + $0.penalty) < ($1.time + $1.penalty) }
                let trimmedSolves = Array(sortedSolves.dropFirst().dropLast())
                guard !trimmedSolves.isEmpty else { continue }
                let totalTime = trimmedSolves.reduce(0) { $0 + $1.time + $1.penalty }
                average = Double(totalTime) / Double(trimmedSolves.count) / 1000.0
            }
            
            if bestAverage == nil || average < bestAverage! {
                bestAverage = average
                bestSolves = groupSolves
            }
        }
        
        return bestSolves
    }
}
