import SwiftUI

struct CubeScrambleView: View {
    let scramble: String

    var body: some View {
        VStack(spacing: 16) {
            // 打乱公式显示
            
            VStack(spacing: 8) {
                Text("SCRAMBLE")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .tracking(2)
                
                Text(scramble)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            CubeNetView(scramble: scramble)
                .frame(width: 200, height: 150)
                .padding(.leading, 40)
                .padding(.top, 40)
                .scaleEffect(1.2)
             

        
        }
        .padding(.top,60)
    }

}

#if DEBUG
struct CubeScrambleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CubeScrambleView(scramble: "R U R' U' R2 F2")
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
