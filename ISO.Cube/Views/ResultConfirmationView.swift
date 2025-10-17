import SwiftUI
import AppKit

struct ResultConfirmationView: View {
    let solve: SolveModel
    let onConfirm: (Int, String, String) -> Void // penalty, comment, scramble
    let onCancel: () -> Void
    let onDelete: () -> Void // delete the solve
    
    @State private var selectedPenalty: Int = 0
    @State private var comment: String = ""
    @State private var scramble: String = ""
    @State private var isShowingKeyboard = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Main confirmation card
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Confirm Result")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(solve.displayTime)
                        .font(.system(size: 32, weight: .light, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                // Penalty buttons
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        PenaltyButton(
                            title: "OK",
                            isSelected: selectedPenalty == 0,
                            color: .green
                        ) {
                            selectedPenalty = 0
                        }
                        
                        PenaltyButton(
                            title: "+2",
                            isSelected: selectedPenalty == 2000,
                            color: .orange
                        ) {
                            selectedPenalty = 2000
                        }
                        
                        PenaltyButton(
                            title: "DNF",
                            isSelected: selectedPenalty == -1,
                            color: .red
                        ) {
                            selectedPenalty = -1
                        }
                    }
                    
                    // Keyboard shortcuts hint
                    Text("Enter to confirm • ESC to cancel")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Scramble input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scramble")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextField("Scramble sequence...", text: $scramble)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.8))
                        .onTapGesture {
                            isShowingKeyboard = true
                        }
                }
                
                // Comment input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comment (optional)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextField("Add a comment...", text: $comment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.8))
                        .onTapGesture {
                            isShowingKeyboard = true
                        }
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Delete") {
                        onDelete()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Confirm") {
                        onConfirm(selectedPenalty, comment, scramble)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .frame(width: 320)
            .scaleEffect(isShowingKeyboard ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isShowingKeyboard)
        }
        .onAppear {
            // Initialize scramble with the original value
            scramble = solve.scramble
            
            // Initialize penalty with the original value
            selectedPenalty = solve.penalty
            
            // Initialize comment with the original value
            comment = solve.comment
            
            // Add keyboard event monitoring
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                switch event.keyCode {
                case 36: // Enter key
                    onConfirm(selectedPenalty, comment, scramble)
                    return nil
                case 53: // ESC key
                    onCancel()
                    return nil
                default:
                    return event
                }
            }
        }
    }
}

struct PenaltyButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : color)
                .frame(width: 80, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? color : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(color, lineWidth: 2)
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 100, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 100, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

