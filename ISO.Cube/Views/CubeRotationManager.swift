import SceneKit
import Foundation

final class CubeRotationManager {
    let cubeNode: SCNNode
    let scene: SCNScene
    private var isAnimating: Bool = false
    private var moveQueue: [String] = []

    init(cubeNode: SCNNode, scene: SCNScene) {
        self.cubeNode = cubeNode
        self.scene = scene
    }

    /// Public API: Apply cube rotation moves like "U", "U'", "R", "R'" etc.
    func applyMove(_ move: String) {
        let normalizedMove = move.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // If currently animating, buffer this move
        if isAnimating {
            moveQueue.append(normalizedMove)
            return
        }
        executeMove(normalizedMove)
    }

    private func executeMove(_ normalizedMove: String) {
        // Parse the move
        let face = String(normalizedMove.prefix(1))
        let isPrime = normalizedMove.contains("'")
        
        // Determine rotation axis and selector
        guard let (axis, selector) = getAxisAndSelector(for: face) else { return }
        
        // Determine rotation angle (clockwise is positive, counterclockwise is negative)
        let angle = isPrime ? -CGFloat.pi/2 : CGFloat.pi/2
        
        // Execute rotation
        rotateFace(selector: selector, axis: axis, angle: angle)
    }
    
    
    // MARK: - Private Methods
    
    /// Get rotation axis and selector for a face
    private func getAxisAndSelector(for face: String) -> (axis: SCNVector3, selector: (SCNNode) -> Bool)? {
        let threshold: CGFloat = 0.4
        
        switch face {
        case "U": // Up face - rotate around Y axis, select cubies with Y > threshold
            return (SCNVector3(0, 1, 0), { cubie in
                return cubie.position.y < -threshold
            })
        case "D": // Down face - rotate around Y axis, select cubies with Y < -threshold
            return (SCNVector3(0, -1, 0), { cubie in
                return cubie.position.y > threshold
            })
        case "F": // Front face - rotate around Z axis, select cubies with Z > threshold
            return (SCNVector3(0, 0, 1), { cubie in
                return cubie.position.z < -threshold
            })
        case "B": // Back face - rotate around Z axis, select cubies with Z < -threshold
            return (SCNVector3(0, 0, -1), { cubie in
                return cubie.position.z > threshold
            })
        case "R": // Right face - rotate around X axis (flipped direction), select cubies with X > threshold
            return (SCNVector3(-1, 0, 0), { cubie in
                return cubie.position.x > threshold
            })
        case "L": // Left face - rotate around X axis, select cubies with X < -threshold
            return (SCNVector3(1, 0, 0), { cubie in
                return cubie.position.x < -threshold
            })
        default:
            return nil
        }
    }
    
    /// Execute face rotation
    private func rotateFace(selector: (SCNNode) -> Bool, axis: SCNVector3, angle: CGFloat) {
        // Select cubies to rotate first
        let cubiesToRotate = cubeNode.childNodes.filter(selector)

        // If nothing to rotate, don't get stuck in animating state — advance the queue
        guard !cubiesToRotate.isEmpty else {
            // Ensure we are not marked animating when no-op
            self.isAnimating = false
            if let next = self.moveQueue.first {
                self.moveQueue.removeFirst()
                self.executeMove(next)
            }
            return
        }

        // Mark as animating only when we actually have an animation to run
        isAnimating = true
        
        // Create temporary rotation node
        let rotationNode = SCNNode()
        rotationNode.name = "faceRotation"
        cubeNode.addChildNode(rotationNode)
            
        // Move cubies to rotation node
        for cubie in cubiesToRotate {
            rotationNode.addChildNode(cubie)
        }
        
        // Execute rotation animation
        let rotationAction = SCNAction.rotateBy(x: axis.x * angle, y: axis.y * angle, z: axis.z * angle, duration: 0.05)
        rotationAction.timingMode = .easeInEaseOut
        
        rotationNode.runAction(rotationAction) {
            // Ensure SceneKit graph updates and queue progression occur on the main thread
            DispatchQueue.main.async {
                // Save rotated transforms
                var rotatedCubies: [(SCNNode, SCNMatrix4)] = []
                for cubie in cubiesToRotate {
                    let finalTransform = cubie.worldTransform
                    rotatedCubies.append((cubie, finalTransform))
                }
                
                // Move cubies back to cube node and apply rotated transforms
                for (cubie, finalTransform) in rotatedCubies {
                    self.cubeNode.addChildNode(cubie)
                    // Convert world transform to local transform relative to cubeNode
                    let localTransform = self.cubeNode.convertTransform(finalTransform, from: nil)
                    cubie.transform = localTransform
                }
                
                // Clean up temporary rotation node
                rotationNode.removeFromParentNode()

                // Mark animation finished and run next move if queued
                self.isAnimating = false
                if let next = self.moveQueue.first {
                    self.moveQueue.removeFirst()
                    self.executeMove(next)
                }
            }
        }
    }
}
