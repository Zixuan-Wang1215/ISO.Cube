
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


    func initializeCamera() {
        let node = scene!.rootNode.childNode(withName: "camera", recursively: true)!
        let cam = node.camera!
        cameraNodeRef = node
        cubeNodeRef = scene!.rootNode.childNode(withName: "cube", recursively: true)!
        cameraRef = cam
        cam.wantsHDR = true
        cam.saturation = 0.1
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
        let cam = cameraRef!
        let loc = convert(event.locationInWindow, from: nil)

        // Define bottom button region
        let buttonWidth: CGFloat = 40
        let spacing: CGFloat = 40
        let horizontalPadding: CGFloat = 12 * 2
        let barWidth = buttonWidth * 3 + spacing * 2 + horizontalPadding
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
    
    func makeNSView(context: Context) -> SCNView {
        let sceneView = HoverSCNView()
        sceneView.isTimerRunning = isTimerRunning
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
        hoverView.isTimerRunning = isTimerRunning
    }
    
}
