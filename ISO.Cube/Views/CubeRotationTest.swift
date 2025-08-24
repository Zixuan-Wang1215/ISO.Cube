
import SwiftUI
import SceneKit

struct RotationTestView: NSViewRepresentable {
    class Coordinator {
        // Rotation manager for cube operations
        var rotationManager: CubeRotationManager?
        // Timer for automatic rotation testing
        var timer: DispatchSourceTimer?
        // Save initial camera state for reset when needed
        var initialCameraTransform: SCNMatrix4?
        var initialCameraPosition: SCNVector3?
        var initialCameraSaturation: CGFloat?
        deinit {
            timer?.cancel()
            timer = nil
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)

        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = NSColor.clear

        // Load scene
        let scene = SCNScene(named: "3dcube.scn")!
        scnView.scene = scene

        // Find cube node
        let cubeNode = scene.rootNode.childNode(withName: "cube", recursively: true)!

        // Find camera node and initialize its properties
        let cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)!
        let cam = cameraNode.camera!
        cam.wantsHDR = true
        cam.saturation = 1.0

        // Move camera further away
        let onCubePos = SCNVector3(Float(20.83), Float(20.759), Float(20.83))
        cameraNode.position = onCubePos

        // Save initial camera state
        context.coordinator.initialCameraTransform = cameraNode.transform
        context.coordinator.initialCameraPosition = cameraNode.position
        context.coordinator.initialCameraSaturation = CGFloat(cam.saturation)

        // Create rotation manager
        let manager = CubeRotationManager(cubeNode: cubeNode, scene: scene)
        context.coordinator.rotationManager = manager

        // Execute action every 2 seconds
        let moves = ["R", "U", "F", "D", "L", "B"]
        var i = 0
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + 1, repeating: 1, leeway: .seconds(1))
        timer.setEventHandler { [weak manager] in
            guard let m = manager else { return }
            m.applyMove(moves[i])
            print(moves[i])
            i = i + 1
            if i == 6 {
                i = 0
            }
        }
        timer.resume()
        context.coordinator.timer = timer

        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
    }

    static func dismantleNSView(_ nsView: SCNView, coordinator: Coordinator) {
        // Clean up resources when view is dismantled
        coordinator.timer?.cancel()
        coordinator.timer = nil
        coordinator.rotationManager = nil
    }
}
