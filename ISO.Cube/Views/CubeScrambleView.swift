import SwiftUI

struct CubeScrambleView: View {
    @Binding var scramble: String
    @State private var isEditing = false
    @State private var editingText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Button(action: {
                        generateNewScramble()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isEditing)
                    .opacity(isEditing ? 0.3 : 1.0)
                    
                    Spacer()
                    
                    Text(LocalizationKey.scramble.localized.uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(2)
                    
                    Spacer()
                    
                    // Invisible spacer to balance the layout
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.clear)
                }
                
                if isEditing {
                    TextField(LocalizationKey.enterScramble.localized, text: $editingText)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            confirmEdit()
                        }
                        .onAppear {
                            editingText = scramble
                            isTextFieldFocused = true
                        }
                        .onChange(of: isTextFieldFocused) { previous, current in
                            // macOS 14+ provides previous and current values. Confirm edit when focus is lost.
                            if !current {
                                confirmEdit()
                            }
                        }
                } else {
                    Text(scramble)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .onTapGesture {
                            startEditing()
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 20)
            .frame(maxWidth: 750)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(isEditing ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            
            CubeNetView(scramble: scramble)
                .frame(width: 300, height: 150)
                .padding(.leading, 40)
                .padding(.top, 30)
               
        }
        .padding(.top, 60)
    }
    
    private func startEditing() {
        isEditing = true
        editingText = scramble
    }
    
    private func confirmEdit() {
        scramble = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditing = false
    }
    
    private func generateNewScramble() {
        scramble = ScrambleModel.generateScramble()
    }
}
