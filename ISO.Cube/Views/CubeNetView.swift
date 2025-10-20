import SwiftUI

struct CubeNetView: View {
    let scramble: String
    
    // Define cube colors with enhanced vibrancy
    private let colors: [String: Color] = [
        "U": Color(red: 0.98, green: 0.98, blue: 0.98),    // Up face - bright white
        "D": Color(red: 1.0, green: 0.95, blue: 0.0),      // Down face - vibrant yellow
        "F": Color(red: 0.0, green: 0.8, blue: 0.2),       // Front face - bright green
        "B": Color(red: 0.0, green: 0.4, blue: 1.0),       // Back face - bright blue
        "L": Color(red: 1.0, green: 0.6, blue: 0.0),       // Left face - vibrant orange
        "R": Color(red: 0.9, green: 0.1, blue: 0.1)        // Right face - bright red
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
    
    // Generate cube state string in URFDLB format
    func getCubeStateString() -> String {
        let cubeState = getCubeState()
        var result = ""
        
        // 按照 U, R, F, D, L, B 的顺序读取
        let faceOrder = [0, 5, 2, 1, 4, 3] // U, R, F, D, L, B
        
        for faceIndex in faceOrder {
            for row in 0..<3 {
                for col in 0..<3 {
                    result += cubeState[faceIndex][row][col]
                }
            }
        }
        
        return result
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
        if direction == "2" {
            // Execute two clockwise rotations
            uTurn(&cube, direction: "")
            uTurn(&cube, direction: "")
        } else {
            // Rotate U face itself
            if direction == "'" {
                cube[0] = rotateFaceCounterClockwise(cube[0])
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
            } else { // Clockwise
                cube[2][0] = cube[5][0]
                cube[5][0] = cube[3][0]
                cube[3][0] = cube[4][0]
                cube[4][0] = temp
            }
        }
    }
    
    // D face rotation
    private func dTurn(_ cube: inout [[[String]]], direction: String) {
        if direction == "2" {
            // Execute two clockwise rotations
            dTurn(&cube, direction: "")
            dTurn(&cube, direction: "")
        } else {
            // Rotate D face itself
            if direction == "'" {
                cube[1] = rotateFaceCounterClockwise(cube[1])
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
            } else { // Clockwise
                cube[2][2] = cube[4][2]
                cube[4][2] = cube[3][2]
                cube[3][2] = cube[5][2]
                cube[5][2] = temp
            }
        }
    }
    
    // F face rotation
    private func fTurn(_ cube: inout [[[String]]], direction: String) {
        if direction == "2" {
            // Execute two clockwise rotations
            fTurn(&cube, direction: "")
            fTurn(&cube, direction: "")
        } else {
            // Rotate F face itself
            if direction == "'" {
                cube[2] = rotateFaceCounterClockwise(cube[2])
            } else {
                cube[2] = rotateFaceClockwise(cube[2])
            }
            
            // Rotate adjacent faces' edges
            // U面底部行 (cube[0][2])
            // R面左侧列 (cube[5][i][0])
            // D面顶部行 (cube[1][0])
            // L面右侧列 (cube[4][i][2])
            let temp = cube[0][2]
            
            if direction == "'" { // Counterclockwise
                // U面底部 = R面左侧列（从上到下）
                cube[0][2] = [cube[5][0][0], cube[5][1][0], cube[5][2][0]]
                // R面左侧列 = D面顶部（从右到左，需要颠倒）
                cube[5][0][0] = cube[1][0][2]
                cube[5][1][0] = cube[1][0][1]
                cube[5][2][0] = cube[1][0][0]
                // D面顶部 = L面右侧列（从右到左，需要颠倒）
                cube[1][0] = [cube[4][0][2], cube[4][1][2], cube[4][2][2]]
                // L面右侧列 = U面底部（从上到下，需要颠倒）
                cube[4][0][2] = temp[2]
                cube[4][1][2] = temp[1]
                cube[4][2][2] = temp[0]
            } else { // Clockwise
                // U面底部 = L面右侧列（从上到下，需要颠倒）
                cube[0][2] = [cube[4][2][2], cube[4][1][2], cube[4][0][2]]
                // L面右侧列 = D面顶部（从右到左，需要颠倒）
                cube[4][0][2] = cube[1][0][0]
                cube[4][1][2] = cube[1][0][1]
                cube[4][2][2] = cube[1][0][2]
                // D面顶部 = R面左侧列（从右到左，需要颠倒）
                cube[1][0] = [cube[5][2][0], cube[5][1][0], cube[5][0][0]]
                // R面左侧列 = U面底部（从上到下，需要颠倒）
                cube[5][0][0] = temp[0]
                cube[5][1][0] = temp[1]
                cube[5][2][0] = temp[2]
            }
        }
    }
    
    // B face rotation
    private func bTurn(_ cube: inout [[[String]]], direction: String) {
        if direction == "2" {
            // Execute two clockwise rotations
            bTurn(&cube, direction: "")
            bTurn(&cube, direction: "")
        } else {
            // Rotate B face itself
            if direction == "'" {
                cube[3] = rotateFaceCounterClockwise(cube[3])
            } else {
                cube[3] = rotateFaceClockwise(cube[3])
            }
            
            // Rotate adjacent faces' edges
            // U面顶部行 (cube[0][0])
            // L面左侧列 (cube[4][i][0])
            // D面底部行 (cube[1][2])
            // R面右侧列 (cube[5][i][2])
            let temp = cube[0][0]

            if direction == "'" { // Counterclockwise
                // U面顶部 = L面左侧列（从下到上）
                cube[0][0] = [cube[4][2][0], cube[4][1][0], cube[4][0][0]]
                // L面左侧列 = D面底部（从左到右）
                cube[4][0][0] = cube[1][2][0]
                cube[4][1][0] = cube[1][2][1]
                cube[4][2][0] = cube[1][2][2]
                // D面底部 = R面右侧列（从下到上，需要反转）
                cube[1][2] = [cube[5][2][2], cube[5][1][2], cube[5][0][2]]
                // R面右侧列 = U面顶部（从上到下）
                cube[5][0][2] = temp[0]
                cube[5][1][2] = temp[1]
                cube[5][2][2] = temp[2]
            } else { // Clockwise
                // U面顶部 = R面右侧列（从上到下）
                cube[0][0] = [cube[5][0][2], cube[5][1][2], cube[5][2][2]]
                // R面右侧列 = D面底部（从下到上，需要反转）
                cube[5][0][2] = cube[1][2][2]
                cube[5][1][2] = cube[1][2][1]
                cube[5][2][2] = cube[1][2][0]
                // D面底部 = L面左侧列（从上到下）
                cube[1][2] = [cube[4][0][0], cube[4][1][0], cube[4][2][0]]
                // L面左侧列 = U面顶部（从下到上，需要反转）
                cube[4][0][0] = temp[2]
                cube[4][1][0] = temp[1]
                cube[4][2][0] = temp[0]
            }
        }
    }
    
    // L face rotation
    private func lTurn(_ cube: inout [[[String]]], direction: String) {
        if direction == "2" {
            // Execute two clockwise rotations
            lTurn(&cube, direction: "")
            lTurn(&cube, direction: "")
        } else {
            // Rotate L face itself
            if direction == "'" {
                cube[4] = rotateFaceCounterClockwise(cube[4])
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
            } else { // Clockwise
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
    }
    
    // R face rotation
    private func rTurn(_ cube: inout [[[String]]], direction: String) {
        if direction == "2" {
            // Execute two clockwise rotations
            rTurn(&cube, direction: "")
            rTurn(&cube, direction: "")
        } else {
            // Rotate R face itself
            if direction == "'" {
                cube[5] = rotateFaceCounterClockwise(cube[5])
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
            } else { // Clockwise
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
            let cornerRadius: CGFloat = 4

            Group {
                if size > 0 {
                    Canvas { context, _ in
                        // Canvas drawing when size is valid
                        // Define positions for the unfolded net: top, middle row of 4, bottom
                        let positions: [(Int, Int, Int)] = [
                            // Top face centered above
                            (1, 0, 0), // Up face
                            // Middle row: left, front, right, back
                            (0, 1, 4), (1, 1, 2), (2, 1, 5), (3, 1, 3), // Left, Front, Right, Back
                            // Bottom face
                            (1, 2, 1)  // Down face
                        ]
                        
                        // No shadows - removed for clean look
                        
                        let spacing: CGFloat = 6 // Spacing between faces
                        
                        for pos in positions {
                            let x = CGFloat(pos.0) * cell + CGFloat(pos.0) * spacing
                            let y = CGFloat(pos.1) * cell + CGFloat(pos.1) * spacing
                            let faceIndex = pos.2
                            let rect = CGRect(x: x, y: y, width: cell, height: cell)
                            
                            // Draw each small cell within face with 1px spacing
                            let stickerSpacing: CGFloat = 1
                            let stickerSize = (cell - 2 * stickerSpacing) / 3
                            
                            for row in 0..<3 {
                                for col in 0..<3 {
                                    let cellRect = CGRect(
                                        x: rect.minX + CGFloat(col) * (stickerSize + stickerSpacing) + stickerSpacing,
                                        y: rect.minY + CGFloat(row) * (stickerSize + stickerSpacing) + stickerSpacing,
                                        width: stickerSize,
                                        height: stickerSize)
                                    
                                    // Get color
                                    let colorName = cubeState[faceIndex][row][col]
                                    let baseColor = colors[colorName] ?? .gray
                                    
                                    // Draw solid color background - no textures
                                    var fillPath = Path()
                                    fillPath.addRoundedRect(in: cellRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
                                    context.fill(fillPath, with: .color(baseColor))
                                    
                                    // Draw subtle border
                                    var borderPath = Path()
                                    borderPath.addRoundedRect(in: cellRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
                                    context.stroke(borderPath, with: .color(.black.opacity(0.2)), lineWidth: 0.5)
                                }
                            }

                            // No face boundary - removed white borders
                        }
                    }
                } else {
                    // Avoid creating a Canvas with zero drawable size which can log CAMetalLayer warnings
                    Color.clear
                }
            }
        }
        .frame(height: 220)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 8)
    }
}
