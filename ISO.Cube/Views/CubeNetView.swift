import SwiftUI

struct CubeNetView: View {
    let scramble: String
    
    // 定义魔方颜色
    private let colors: [String: Color] = [
        "U": .white,    // 上面 - 白色
        "D": .yellow,   // 下面 - 黄色
        "F": .green,    // 前面 - 绿色
        "B": .blue,     // 后面 - 蓝色
        "L": .orange,   // 左面 - 橙色
        "R": .red       // 右面 - 红色
    ]
    
    // 计算打乱后的颜色状态
    private func getCubeState() -> [[[String]]] {
        // 初始化已解决的魔方状态
        let faces = ["U", "D", "F", "B", "L", "R"]
        var cube: [[[String]]] = faces.map { face in
            Array(repeating: Array(repeating: face, count: 3), count: 3)
        }
        
        // 解析打乱公式并应用
        let moves = scramble.components(separatedBy: " ")
        for move in moves {
            if !move.isEmpty {
                applyMove(&cube, move: move)
            }
        }
        
        return cube
    }
    
    // 应用单个移动
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
    
    // U面旋转
    private func uTurn(_ cube: inout [[[String]]], direction: String) {
        // 旋转U面本身
        if direction == "'" {
            cube[0] = rotateFaceCounterClockwise(cube[0])
        } else if direction == "2" {
            cube[0] = rotateFace180(cube[0])
        } else {
            cube[0] = rotateFaceClockwise(cube[0])
        }
        
        // 旋转相邻面的上边
        let temp = cube[2][0]
        
        if direction == "'" { // 逆时针
            cube[2][0] = cube[4][0]
            cube[4][0] = cube[3][0]
            cube[3][0] = cube[5][0]
            cube[5][0] = temp
        } else { // 顺时针或180度
            cube[2][0] = cube[5][0]
            cube[5][0] = cube[3][0]
            cube[3][0] = cube[4][0]
            cube[4][0] = temp
        }
    }
    
    // D面旋转
    private func dTurn(_ cube: inout [[[String]]], direction: String) {
        // 旋转D面本身
        if direction == "'" {
            cube[1] = rotateFaceCounterClockwise(cube[1])
        } else if direction == "2" {
            cube[1] = rotateFace180(cube[1])
        } else {
            cube[1] = rotateFaceClockwise(cube[1])
        }
        
        // 旋转相邻面的下边
        let temp = cube[2][2]
        
        if direction == "'" { // 逆时针
            cube[2][2] = cube[5][2]
            cube[5][2] = cube[3][2]
            cube[3][2] = cube[4][2]
            cube[4][2] = temp
        } else { // 顺时针或180度
            cube[2][2] = cube[4][2]
            cube[4][2] = cube[3][2]
            cube[3][2] = cube[5][2]
            cube[5][2] = temp
        }
    }
    
    // F面旋转
    private func fTurn(_ cube: inout [[[String]]], direction: String) {
        // 旋转F面本身
        if direction == "'" {
            cube[2] = rotateFaceCounterClockwise(cube[2])
        } else if direction == "2" {
            cube[2] = rotateFace180(cube[2])
        } else {
            cube[2] = rotateFaceClockwise(cube[2])
        }
        
        // 旋转相邻面的边
        let temp = cube[0][2]
        
        if direction == "'" { // 逆时针
            cube[0][2] = cube[5][0]
            cube[5][0] = cube[1][0].reversed()
            cube[1][0] = cube[4][2]
            cube[4][2] = temp.reversed()
        } else { // 顺时针或180度
            cube[0][2] = cube[4][2].reversed()
            cube[4][2] = cube[1][0]
            cube[1][0] = cube[5][0].reversed()
            cube[5][0] = temp
        }
    }
    
    // B面旋转
    private func bTurn(_ cube: inout [[[String]]], direction: String) {
        // 旋转B面本身
        if direction == "'" {
            cube[3] = rotateFaceCounterClockwise(cube[3])
        } else if direction == "2" {
            cube[3] = rotateFace180(cube[3])
        } else {
            cube[3] = rotateFaceClockwise(cube[3])
        }
        
        // 旋转相邻面的边
        let temp = cube[0][0]
        
        if direction == "'" { // 逆时针
            cube[0][0] = cube[4][0].reversed()
            cube[4][0] = cube[1][2]
            cube[1][2] = cube[5][2].reversed()
            cube[5][2] = temp
        } else { // 顺时针或180度
            cube[0][0] = cube[5][2]
            cube[5][2] = cube[1][2].reversed()
            cube[1][2] = cube[4][0]
            cube[4][0] = temp.reversed()
        }
    }
    
    // L面旋转
    private func lTurn(_ cube: inout [[[String]]], direction: String) {
        // 旋转L面本身
        if direction == "'" {
            cube[4] = rotateFaceCounterClockwise(cube[4])
        } else if direction == "2" {
            cube[4] = rotateFace180(cube[4])
        } else {
            cube[4] = rotateFaceClockwise(cube[4])
        }
        
        // 旋转相邻面的边
        let temp = [cube[0][0][0], cube[0][1][0], cube[0][2][0]]
        
        if direction == "'" { // 逆时针
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
        } else { // 顺时针或180度
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
    
    // R面旋转
    private func rTurn(_ cube: inout [[[String]]], direction: String) {
        // 旋转R面本身
        if direction == "'" {
            cube[5] = rotateFaceCounterClockwise(cube[5])
        } else if direction == "2" {
            cube[5] = rotateFace180(cube[5])
        } else {
            cube[5] = rotateFaceClockwise(cube[5])
        }
        
        // 旋转相邻面的边
        let temp = [cube[0][0][2], cube[0][1][2], cube[0][2][2]]
        
        if direction == "'" { // 逆时针
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
        } else { // 顺时针或180度
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
    
    // 顺时针旋转面
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
    
    // 逆时针旋转面
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
    
    // 180度旋转面
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
                    (1, 0, 0), // 上面
                    // Middle row: left, front, right, back
                    (0, 1, 4), (1, 1, 2), (2, 1, 5), (3, 1, 3), // 左、前、右、后
                    // Bottom face
                    (1, 2, 1)  // 下面
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
                            
                            // 获取颜色
                            let colorName = cubeState[faceIndex][row][col]
                            let color = colors[colorName] ?? .gray
                            
                            // 绘制填充色块
                            var fillPath = Path()
                            fillPath.addRect(cellRect)
                            context.fill(fillPath, with: .color(color))
                            
                            // 绘制边框
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

struct CubeNetView_Previews: PreviewProvider {
    static var previews: some View {
        CubeNetView(scramble: "U' L' B")
            .preferredColorScheme(.dark)
            .frame(width: 300, height: 200)
    }
}
