import Foundation
import SwiftUI

class HistoryManager: ObservableObject {
    @Published var sessions: [SessionModel] = []
    @Published var currentSessionId: String?
    
    private let fileName = "solve_history.json"
    private var fileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }
    
    var currentSession: SessionModel? {
        guard let currentSessionId = currentSessionId else { return nil }
        return sessions.first { $0.id == currentSessionId }
    }
    
    init() {
        loadHistory()
        if sessions.isEmpty {
            createDefaultSession()
        }
        if currentSessionId == nil {
            currentSessionId = sessions.first?.id
        }
    }
    
    // MARK: - File Operations
    
    private func loadHistory() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let historyData = try decoder.decode(HistoryData.self, from: data)
            
            self.sessions = historyData.sessions
            self.currentSessionId = historyData.currentSession
        } catch {
            print("Failed to load history: \(error)")
            // If file doesn't exist or is corrupted, start with empty sessions
            self.sessions = []
            self.currentSessionId = nil
        }
    }
    
    func saveHistory() {
        do {
            let historyData = HistoryData(sessions: sessions, currentSession: currentSessionId)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(historyData)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
    
    // MARK: - Session Management
    
    func createDefaultSession() {
        let defaultSession = SessionModel(name: "Session 1")
        sessions.append(defaultSession)
        currentSessionId = defaultSession.id
        saveHistory()
    }
    
    func createSession(name: String) -> Bool {
        // Check for duplicate names
        if sessions.contains(where: { $0.name.lowercased() == name.lowercased() }) {
            return false
        }
        
        let newSession = SessionModel(name: name)
        sessions.append(newSession)
        saveHistory()
        return true
    }
    
    func renameSession(id: String, newName: String) -> Bool {
        // Check for duplicate names (excluding current session)
        if sessions.contains(where: { $0.id != id && $0.name.lowercased() == newName.lowercased() }) {
            return false
        }
        
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].name = newName
            saveHistory()
            return true
        }
        return false
    }
    
    func deleteSession(id: String) -> Bool {
        // Don't allow deleting the last session
        if sessions.count <= 1 {
            return false
        }
        
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions.remove(at: index)
            
            // If we deleted the current session, switch to the first available session
            if currentSessionId == id {
                currentSessionId = sessions.first?.id
            }
            
            saveHistory()
            return true
        }
        return false
    }
    
    func setCurrentSession(id: String) {
        if sessions.contains(where: { $0.id == id }) {
            currentSessionId = id
            saveHistory()
        }
    }
    
    // MARK: - Solve Management
    
    func addSolve(_ solve: SolveModel) {
        guard let currentSessionId = currentSessionId,
              let index = sessions.firstIndex(where: { $0.id == currentSessionId }) else {
            return
        }
        
        sessions[index].addSolve(solve)
        saveHistory()
    }
    
    func removeSolve(sessionId: String, solveId: UUID) {
        guard let sessionIndex = sessions.firstIndex(where: { $0.id == sessionId }) else {
            return
        }
        
        sessions[sessionIndex].removeSolve(withId: solveId)
        saveHistory()
    }
    
    // MARK: - Statistics
    
    func getSessionStatistics(for sessionId: String) -> SessionStatistics? {
        guard let session = sessions.first(where: { $0.id == sessionId }) else {
            return nil
        }
        
        return SessionStatistics(
            solveCount: session.solveCount,
            bestTime: session.bestTime,
            averageTime: session.averageTime,
            dnfCount: session.dnfCount,
            plus2Count: session.plus2Count
        )
    }
    
    // MARK: - Export/Import
    
    func exportToCsTimerFormat() -> String {
        var csTimerData: [String: Any] = [:]
        
        for (index, session) in sessions.enumerated() {
            let sessionKey = "session\(index + 1)"
            let solves = session.solves.map { $0.toCsTimerFormat() }
            csTimerData[sessionKey] = solves
        }
        
        // Add session properties
        var properties: [String: Any] = [:]
        for (index, session) in sessions.enumerated() {
            let sessionKey = "\(index + 1)"
            properties[sessionKey] = [
                "name": session.name,
                "opt": [:],
                "rank": index + 1,
                "stat": [session.solveCount, session.dnfCount, session.averageTime ?? 0.0],
                "date": [session.createdAt, session.solves.last?.timestamp ?? session.createdAt]
            ]
        }
        
        csTimerData["properties"] = ["sessionData": try! JSONSerialization.data(withJSONObject: properties).base64EncodedString()]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: csTimerData, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}

// MARK: - Supporting Types

struct HistoryData: Codable {
    var sessions: [SessionModel]
    var currentSession: String?
}

struct SessionStatistics {
    let solveCount: Int
    let bestTime: Int?
    let averageTime: Double?
    let dnfCount: Int
    let plus2Count: Int
}
