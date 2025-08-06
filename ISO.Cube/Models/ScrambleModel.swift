import Foundation

struct ScrambleModel {
    static func generateScramble(length: Int = 20) -> String {
        // Define all moves with modifiers
        let moves = ["F", "F'", "F2",
                     "R", "R'", "R2",
                     "U", "U'", "U2",
                     "L", "L'", "L2",
                     "B", "B'", "B2",
                     "D", "D'", "D2"]
        var scramble: [String] = []
        var lastFace: String? = nil
        var secondLastFace: String? = nil

        for _ in 0..<length {
            var move: String
            var face: String
            repeat {
                move = moves.randomElement()!
                face = String(move.prefix(1))
            } while face == lastFace || face == secondLastFace

            scramble.append(move)
            secondLastFace = lastFace
            lastFace = face
        }

        return scramble.joined(separator: " ")
    }
}


