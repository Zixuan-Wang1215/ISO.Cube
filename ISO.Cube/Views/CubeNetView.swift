import SwiftUI

struct CubeNetView: View {
    let scramble: String
    
    // Define cube colors
    private let colors: [String: Color] = [
        "U": .white,    // Up face - white
        "D": .yellow,   // Down face - yellow
        "F": .green,    // Front face - green
        "B": .blue,     // Back face - blue
        "L": .orange,   // Left face - orange
        "R": .red       // Right face - red
    ]
    
    // Calculate color state after scramble
    private func getCubeState() -> [[[String]]] {
        // Initialize solved cube state
        let faces = ["U", "D", "F", "B", "L", "R"]
        var cube: [[[String]]] = faces.map { face in
            Array(repeating: Array(repeating: face, count: 3), count: 3)
        }
        
        // Parse scramble formula and apply
        let moves = scramble.components(separatedBy: " ")
        for move in moves {
            if !move.isEmpty {
                applyMove(&cube, move: move)
            }
        }
        
        return cube
    }
    
    // Apply single move
    private func applyMove(_ cube: inout [[[String]]], move: String) {
        let face = String(move.prefix(1))
        let modifier = move.count > 1 ? String(move.suffix(move.count - 1)) : ""
        
        if face == "U" {
            uTurn(&cube, direction: modifier)
        } else if face == "D" {
            dTurn(&cube, direction: modifier)
        } else if face == "F" {
            fTurn(&cube, direction: modifier)
        } else if face == "B" {
            bTurn(&cube, direction: modifier)
        } else if face == "L" {
            lTurn(&cube, direction: modifier)
        } else if face == "R" {
            rTurn(&cube, direction: modifier)
        }
    }
    
    // U face rotation
    private func uTurn(_ cube: inout [[[String]]], direction: String) {
        // Rotate U face itself
        if direction == "'" {
            cube[0] = rotateFaceCounterClockwise(cube[0])
        } else if direction == "2" {
            cube[0] = rotateFace180(cube[0])
        } else {
            cube[0] = rotateFaceClockwise(cube[0])
        }
        
        // Rotate adjacent faces' top edges
        let temp = cube[2][0]
        
        if direction == "'" { // Counterclockwise
            cube[2][0] = cube[4][0]
            cube[4][0] = cube[3][0]
            cube[3][0] = cube[5][0]
            cube[5][0] = temp
        } else { // Clockwise or 180 degrees
            cube[2][0] = cube[5][0]
            cube[5][0] = cube[3][0]
            cube[3][0] = cube[4][0]
            cube[4][0] = temp
        }
    }
    
    // D face rotation
    private func dTurn(_ cube: inout [[[String]]], direction: String) {
        // Rotate D face itself
        if direction == "'" {
            cube[1] = rotateFaceCounterClockwise(cube[1])
        } else if direction == "2" {
            cube[1] = rotateFace180(cube[1])
        } else {
            cube[1] = rotateFaceClockwise(cube[1])
        }
        
        // Rotate adjacent faces' bottom edges
        let temp = cube[2][2]
        
        if direction == "'" { // Counterclockwise
            cube[2][2] = cube[5][2]
            cube[5][2] = cube[3][2]
            cube[3][2] = cube[4][2]
            cube[4][2] = temp
        } else { // Clockwise or 180 degrees
            cube[2][2] = cube[4][2]
            cube[4][2] = cube[3][2]
            cube[3][2] = cube[5][2]
            cube[5][2] = temp
        }
    }
    
    // F face rotation
    private func fTurn(_ cube: inout [[[String]]], direction: String) {
        // Rotate F face itself
        if direction == "'" {
            cube[2] = rotateFaceCounterClockwise(cube[2])
        } else if direction == "2" {
            cube[2] = rotateFace180(cube[2])
        } else {
            cube[2] = rotateFaceClockwise(cube[2])
        }
        
        // Rotate adjacent faces' edges
        let temp = cube[0][2]
        
        if direction == "'" { // Counterclockwise
            cube[0][2] = cube[5][0]
            cube[5][0] = cube[1][0].reversed()
            cube[1][0] = cube[4][2]
            cube[4][2] = temp.reversed()
        } else { // Clockwise or 180 degrees
            cube[0][2] = cube[4][2].reversed()
            cube[4][2] = cube[1][0]
            cube[1][0] = cube[5][0].reversed()
            cube[5][0] = temp
        }
    }
    
    // B face rotation
    private func bTurn(_ cube: inout [[[String]]], direction: String) {
        // Rotate B face itself
        if direction == "'" {
            cube[3] = rotateFaceCounterClockwise(cube[3])
        } else if direction == "2" {
            cube[3] = rotateFace180(cube[3])
        } else {
            cube[3] = rotateFaceClockwise(cube[3])
        }
        
        // Rotate adjacent faces' edges
        let temp = cube[0][0]
        
        if direction == "'" { // Counterclockwise
            cube[0][0] = cube[4][0].reversed()
            cube[4][0] = cube[1][2]
            cube[1][2] = cube[5][2].reversed()
            cube[5][2] = temp
        } else { // Clockwise or 180 degrees
            cube[0][0] = cube[5][2]
            cube[5][2] = cube[1][2].reversed()
            cube[1][2] = cube[4][0]
            cube[4][0] = temp.reversed()
        }
    }
    
    // L face rotation
    private func lTurn(_ cube: inout [[[String]]], direction: String) {
        // Rotate L face itself
        if direction == "'" {
            cube[4] = rotateFaceCounterClockwise(cube[4])
        } else if direction == "2" {
            cube[4] = rotateFace180(cube[4])
        } else {
            cube[4] = rotateFaceClockwise(cube[4])
        }
        
        // Rotate adjacent faces' edges
        let temp = [cube[0][0][0], cube[0][1][0], cube[0][2][0]]
        
        if direction == "'" { // Counterclockwise
            cube[0][0][0] = cube[2][0][0]
            cube[0][1][0] = cube[2][1][0]
            cube[0][2][0] = cube[2][2][0]
            cube[2][0][0] = cube[1][0][0]
            cube[2][1][0] = cube[1][1][0]
            cube[2][2][0] = cube[1][2][0]
            cube[1][0][0] = cube[3][2][2]
            cube[1][1][0] = cube[3][1][2]
            cube[1][2][0] = cube[3][0][2]
            cube[3][0][2] = temp[2]
            cube[3][1][2] = temp[1]
            cube[3][2][2] = temp[0]
        } else { // Clockwise or 180 degrees
            cube[0][0][0] = cube[3][2][2]
            cube[0][1][0] = cube[3][1][2]
            cube[0][2][0] = cube[3][0][2]
            cube[3][0][2] = cube[1][2][0]
            cube[3][1][2] = cube[1][1][0]
            cube[3][2][2] = cube[1][0][0]
            cube[1][0][0] = cube[2][0][0]
            cube[1][1][0] = cube[2][1][0]
            cube[1][2][0] = cube[2][2][0]
            cube[2][0][0] = temp[0]
            cube[2][1][0] = temp[1]
            cube[2][2][0] = temp[2]
        }
    }
    
    // R face rotation
    private func rTurn(_ cube: inout [[[String]]], direction: String) {
        // Rotate R face itself
        if direction == "'" {
            cube[5] = rotateFaceCounterClockwise(cube[5])
        } else if direction == "2" {
            cube[5] = rotateFace180(cube[5])
        } else {
            cube[5] = rotateFaceClockwise(cube[5])
        }
        
        // Rotate adjacent faces' edges
        let temp = [cube[0][0][2], cube[0][1][2], cube[0][2][2]]
        
        if direction == "'" { // Counterclockwise
            cube[0][0][2] = cube[3][2][0]
            cube[0][1][2] = cube[3][1][0]
            cube[0][2][2] = cube[3][0][0]
            cube[3][0][0] = cube[1][2][2]
            cube[3][1][0] = cube[1][1][2]
            cube[3][2][0] = cube[1][0][2]
            cube[1][0][2] = cube[2][0][2]
            cube[1][1][2] = cube[2][1][2]
            cube[1][2][2] = cube[2][2][2]
            cube[2][0][2] = temp[0]
            cube[2][1][2] = temp[1]
            cube[2][2][2] = temp[2]
        } else { // Clockwise or 180 degrees
            cube[0][0][2] = cube[2][0][2]
            cube[0][1][2] = cube[2][1][2]
            cube[0][2][2] = cube[2][2][2]
            cube[2][0][2] = cube[1][0][2]
            cube[2][1][2] = cube[1][1][2]
            cube[2][2][2] = cube[1][2][2]
            cube[1][0][2] = cube[3][2][0]
            cube[1][1][2] = cube[3][1][0]
            cube[1][2][2] = cube[3][0][0]
            cube[3][0][0] = temp[2]
            cube[3][1][0] = temp[1]
            cube[3][2][0] = temp[0]
        }
    }
    
    // Rotate face clockwise
    private func rotateFaceClockwise(_ face: [[String]]) -> [[String]] {
        let n = face.count
        var rotated = Array(repeating: Array(repeating: "", count: n), count: n)
        for i in 0..<n {
            for j in 0..<n {
                rotated[j][n-1-i] = face[i][j]
            }
        }
        return rotated
    }
    
    // Rotate face counterclockwise
    private func rotateFaceCounterClockwise(_ face: [[String]]) -> [[String]] {
        let n = face.count
        var rotated = Array(repeating: Array(repeating: "", count: n), count: n)
        for i in 0..<n {
            for j in 0..<n {
                rotated[n-1-j][i] = face[i][j]
            }
        }
        return rotated
    }
    
    // Rotate face 180 degrees
    private func rotateFace180(_ face: [[String]]) -> [[String]] {
        return rotateFaceClockwise(rotateFaceClockwise(face))
    }
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cell = size / 4.0
            let cubeState = getCubeState()
            
            Canvas { context, _ in
                // Define positions for the unfolded net: top, middle row of 4, bottom
                let positions: [(Int, Int, Int)] = [
                    // Top face centered above
                    (1, 0, 0), // Up face
                    // Middle row: left, front, right, back
                    (0, 1, 4), (1, 1, 2), (2, 1, 5), (3, 1, 3), // Left, Front, Right, Back
                    // Bottom face
                    (1, 2, 1)  // Down face
                ]
                
                for pos in positions {
                    let x = CGFloat(pos.0) * cell
                    let y = CGFloat(pos.1) * cell
                    let faceIndex = pos.2
                    let rect = CGRect(x: x, y: y, width: cell, height: cell)
                    
                    // Draw each small cell within face
                    for row in 0..<3 {
                        for col in 0..<3 {
                            let cellRect = CGRect(
                                x: rect.minX + CGFloat(col) * cell/3,
                                y: rect.minY + CGFloat(row) * cell/3,
                                width: cell/3,
                                height: cell/3)
                            
                            // Get color
                            let colorName = cubeState[faceIndex][row][col]
                            let color = colors[colorName] ?? .gray
                            
                            // Draw filled color block
                            var fillPath = Path()
                            fillPath.addRect(cellRect)
                            context.fill(fillPath, with: .color(color))
                            
                            // Draw border
                            var borderPath = Path()
                            borderPath.addRect(cellRect)
                            context.stroke(borderPath, with: .color(.black), lineWidth: 0.5)
                        }
                    }
                    
                    // Face boundary
                    var facePath = Path()
                    facePath.addRect(rect)
                    context.stroke(facePath, with: .color(.white), lineWidth: 2)
                }
            }
        }
        .frame(height: 200)    // adjust height as needed
        .padding(.horizontal)
    }
}

