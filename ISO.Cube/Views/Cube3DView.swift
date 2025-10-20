
import AppKit
class HoverSCNView: SCNView {
    private var cameraRef: SCNCamera?
    private var cameraNodeRef: SCNNode?
    private var cubeNodeRef: SCNNode?
    private var isHoveringCube = false
    private var isHoveringButton = false
    private var debugTimer: Timer?
    private let bottomBarHeight: CGFloat = 200
    var isTimerRunning: Bool = false
    var isCubeConfirmed: Bool = false
    var disableInteraction: Bool = false
    var cubeSolution: String = ""
    var forceFullOpacity: Bool = false
    
    // 保存原始状态
    private var originalCameraPosition: SCNVector3?
    private var originalCubePosition: SCNVector3?
    private var originalSaturation: Float = 0.1
    private var originalOpacity: Float = 1.0
    
    // 魔方旋转管理器
    private var rotationManager: CubeRotationManager?
    // 跟踪已处理的移动指令数量，避免重复执行
    public var processedMoveCount: Int = 0
    // 跟踪已处理的解，避免重复执行
    public var lastProcessedSolution: String = ""
    // 跟踪是否已执行过初始解
    public var hasExecutedInitialSolution: Bool = false


    func initializeCamera() {
        let node = scene!.rootNode.childNode(withName: "camera", recursively: true)!
        let cam = node.camera!
        cameraNodeRef = node
        cubeNodeRef = scene!.rootNode.childNode(withName: "cube", recursively: true)!
        cameraRef = cam
        cam.wantsHDR = true
        
        // 如果强制全透明度模式，直接设置为100%并调整camera位置
        if forceFullOpacity {
            cam.saturation = 1.0
            cubeNodeRef!.opacity = 1.0
            // 将camera向后拉10个单位
            let debugCameraPos = SCNVector3(
                node.position.x + 20,
                node.position.y + 6,
                node.position.z + 20
            )
            node.position = debugCameraPos
            // 调整camera视角向下10度
            let currentRotation = node.eulerAngles
            node.eulerAngles = SCNVector3(
                currentRotation.x + CGFloat(Float.pi) / 11, // 10度 = π/18弧度
                currentRotation.y,
                currentRotation.z
            )
        } else {
            cam.saturation = 0.1
        }
        
        // 保存原始状态
        originalCameraPosition = node.position
        originalCubePosition = cubeNodeRef!.position
        originalSaturation = Float(cam.saturation)
        originalOpacity = Float(cubeNodeRef!.opacity)
        
        // 初始化旋转管理器
        if let cubeNode = cubeNodeRef, let scene = self.scene {
            rotationManager = CubeRotationManager(cubeNode: cubeNode, scene: scene)
        }
    }
    
    func applyCubeConfirmedSettings() {
        guard let cameraNode = cameraNodeRef,
              let cubeNode = cubeNodeRef,
              let camera = cameraRef else { return }
        
        // 使用SCNTransaction进行平滑的非线性动画过渡
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.2  // 较长的动画时间
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)  // 自定义贝塞尔曲线，实现ease-in-out效果
        
        // 设置相机位置为 (40, 25, 40)
        let confirmedCameraPos = SCNVector3(40, 25, 40)
        cameraNode.position = confirmedCameraPos
        
        // 设置魔方位置为 (2, 3, 2)
        let confirmedCubePos = SCNVector3(2, 3, 2)
        cubeNode.position = confirmedCubePos
        
        // 设置饱和度为1和透明度为1
        camera.saturation = 1.0
        cubeNode.opacity = 1.0
        
        SCNTransaction.commit()
    }
    
    func restoreOriginalSettings() {
        guard let cameraNode = cameraNodeRef,
              let cubeNode = cubeNodeRef,
              let camera = cameraRef,
              let originalCamPos = originalCameraPosition,
              let originalCubePos = originalCubePosition else { return }
        
        // 使用SCNTransaction进行平滑的非线性动画过渡恢复到原始状态
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0  // 稍微快一点的恢复动画
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)  // 同样的ease-in-out效果
        
        // 恢复相机位置到原始状态
        cameraNode.position = originalCamPos
        
        // 恢复魔方位置到原始状态
        cubeNode.position = originalCubePos
        
        // 恢复饱和度到原始状态
        camera.saturation = CGFloat(originalSaturation)
        
        // 恢复透明度到原始状态
        cubeNode.opacity = CGFloat(originalOpacity)
        
        SCNTransaction.commit()
        
        // 重置解的状态
        lastProcessedSolution = ""
        hasExecutedInitialSolution = false
    }
    
    // 处理魔方移动指令
    func handleMoveInstruction(_ move: String) {
        guard let manager = rotationManager else { return }
        manager.applyMove(move)
    }
    
    // 执行魔方解（无动画）
    func executeCubeSolution(_ solution: String) {
        guard let manager = rotationManager else { return }
        
        // 如果解为空或只有空格，不执行任何操作
        let trimmedSolution = solution.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSolution.isEmpty {
            return
        }
        
        // 避免重复执行相同的解
        if solution != lastProcessedSolution {
            lastProcessedSolution = solution
            hasExecutedInitialSolution = true
            manager.executeSolution(solution, animated: true) // 使用队列系统，但动画速度为0
        }
    }




    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        // Clear old trackingAreas
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        // Only listen to mouseMoved events and limit to visible area
        let opts: NSTrackingArea.Options = [.mouseMoved, .activeAlways, .inVisibleRect]
        let area = NSTrackingArea(rect: .zero, options: opts, owner: self, userInfo: nil)
        addTrackingArea(area)
      
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        // 如果禁用交互、cube已确认连接或强制全透明度模式，禁用鼠标悬浮交互
        if disableInteraction || isCubeConfirmed || forceFullOpacity {
            return
        }
        
        let cam = cameraRef!
        let loc = convert(event.locationInWindow, from: nil)

        // Define bottom button region
        let buttonWidth: CGFloat = 40
        let spacing: CGFloat = 40
        let horizontalPadding: CGFloat = 12 * 2
        let barWidth = buttonWidth * 3 + spacing * 2 + horizontalPadding+50
        let xMin = (bounds.width - barWidth) / 2
        let xMax = xMin + barWidth
        let yThreshold = bottomBarHeight

        // If pointer is over buttons
        if loc.y <= yThreshold && loc.x >= xMin && loc.x <= xMax {
            cam.saturation = 0.1
            // Haptic only on entering button area
            if !isHoveringButton && !isTimerRunning {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                isHoveringButton = true
            }
            // Reset cube hover state
            isHoveringCube = false
            return
        } else {
            // Pointer left button area
            isHoveringButton = false
        }

        // Otherwise, check if over cube
        let hits = hitTest(loc, options: nil)
        let overCube = hits.contains { hit in
            var node = hit.node
            while true {
                if node.name == "cube" { return true }
                if node.parent == nil { break }
                node = node.parent!
            }
            return false
        }

        // Haptic feedback only when moving onto the cube
        if overCube && !isHoveringCube && !isTimerRunning {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            isHoveringCube = true
        } else if !overCube {
            isHoveringCube = false
        }

        // Determine target saturation and camera position
        let targetSaturation: CGFloat = overCube ? 1.0 : 0.1
        let onCubePos  = SCNVector3(14.83,  14.759, 14.83)
        let offCubePos = SCNVector3(14.526, 14.457, 14.526)
        let targetPos = overCube ? onCubePos : offCubePos

        // Animate saturation and camera movement
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cam.saturation = targetSaturation
        // Removed haptic feedback from here
        cameraNodeRef?.position = targetPos
        cubeNodeRef?.opacity = targetSaturation
        SCNTransaction.commit()
    }
}

import SwiftUI
import SceneKit

struct Cube3DView: NSViewRepresentable {
    let isTimerRunning: Bool
    let isCubeConfirmed: Bool
    let moveOutput: String
    let cubeSolution: String
    let hasExecutedInitialSolution: Bool
    let disableInteraction: Bool
    let forceFullOpacity: Bool
    
    func makeNSView(context: Context) -> SCNView {
        let sceneView = HoverSCNView()
        sceneView.isTimerRunning = isTimerRunning
        sceneView.isCubeConfirmed = isCubeConfirmed
        sceneView.disableInteraction = disableInteraction
        sceneView.cubeSolution = cubeSolution
        sceneView.hasExecutedInitialSolution = hasExecutedInitialSolution
        sceneView.forceFullOpacity = forceFullOpacity
        
        // 如果是调试窗口模式，初始化时同步移动计数
        if forceFullOpacity && !moveOutput.isEmpty {
            let lines = moveOutput.components(separatedBy: .newlines)
            let moveLines = lines.filter { $0.hasPrefix("Move:") }
            sceneView.processedMoveCount = moveLines.count
        }
        
        sceneView.scene = SCNScene(named: "3dcube.scn")
        sceneView.initializeCamera()
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false // Disable user drag and rotation
        sceneView.backgroundColor = NSColor.clear
        
        /*
         // Set global lighting for the scene
         let ambientLight = SCNNode()
         ambientLight.light = SCNLight()
         ambientLight.light?.type = .ambient
         ambientLight.light?.intensity = 500
         sceneView.scene?.rootNode.addChildNode(ambientLight)
         */
        let cubeNode = sceneView.scene!.rootNode.childNodes.first!
        // Set cube tilt 45 degrees and expose one corner
        cubeNode.eulerAngles = SCNVector3(-Float.pi / 8, Float.pi / 4, 0)
        // Initialize camera saturation to full
       
        return sceneView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        let hoverView = nsView as! HoverSCNView
        let wasConfirmed = hoverView.isCubeConfirmed
        hoverView.isTimerRunning = isTimerRunning
        hoverView.isCubeConfirmed = isCubeConfirmed
        hoverView.disableInteraction = disableInteraction
        hoverView.cubeSolution = cubeSolution
        hoverView.hasExecutedInitialSolution = hasExecutedInitialSolution
        hoverView.forceFullOpacity = forceFullOpacity
        
        // 如果cube刚刚被确认，应用设置
        if isCubeConfirmed && !wasConfirmed {
            hoverView.applyCubeConfirmedSettings()
        }
        // 如果cube刚刚被取消确认，恢复原始设置
        else if !isCubeConfirmed && wasConfirmed {
            hoverView.restoreOriginalSettings()
            // 重置移动计数器
            hoverView.processedMoveCount = 0
        }
        
        // 处理魔方解和移动输出
        if !moveOutput.isEmpty {
            let lines = moveOutput.components(separatedBy: .newlines)
            let moveLines = lines.filter { $0.hasPrefix("Move:") }
            
            if forceFullOpacity {
                // 调试窗口模式：先执行初始解，然后处理历史移动
                if !cubeSolution.isEmpty && isCubeConfirmed && cubeSolution != hoverView.lastProcessedSolution {
                    hoverView.executeCubeSolution(cubeSolution)
                }
                
                // 处理所有历史移动来同步状态
                if moveLines.count > hoverView.processedMoveCount {
                    let newMoves = Array(moveLines[hoverView.processedMoveCount...])
                    
                    for line in newMoves {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        // 提取移动令牌
                        var moveToken = trimmedLine.replacingOccurrences(of: "Move:", with: "")
                        if let commaIdx = moveToken.firstIndex(of: ",") {
                            moveToken = String(moveToken[..<commaIdx])
                        }
                        moveToken = moveToken.trimmingCharacters(in: .whitespaces)
                        
                        if !moveToken.isEmpty {
                            hoverView.handleMoveInstruction(moveToken)
                        }
                    }
                    
                    // 更新已处理的移动数量
                    hoverView.processedMoveCount = moveLines.count
                }
            } else {
                // 主界面模式：处理初始解
                if !cubeSolution.isEmpty && isCubeConfirmed && cubeSolution != hoverView.lastProcessedSolution {
                    hoverView.executeCubeSolution(cubeSolution)
                }
                
                // 主界面模式：只处理新的移动指令
                if moveLines.count > hoverView.processedMoveCount {
                    let newMoves = Array(moveLines[hoverView.processedMoveCount...])
                    
                    for line in newMoves {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        // 提取移动令牌
                        var moveToken = trimmedLine.replacingOccurrences(of: "Move:", with: "")
                        if let commaIdx = moveToken.firstIndex(of: ",") {
                            moveToken = String(moveToken[..<commaIdx])
                        }
                        moveToken = moveToken.trimmingCharacters(in: .whitespaces)
                        
                        if !moveToken.isEmpty {
                            hoverView.handleMoveInstruction(moveToken)
                        }
                    }
                    
                    // 更新已处理的移动数量
                    hoverView.processedMoveCount = moveLines.count
                }
            }
        }
    }
    
}
