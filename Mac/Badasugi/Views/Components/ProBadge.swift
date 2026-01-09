import SwiftUI

struct ProBadge: View {
    var body: some View {
        Text("정식")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.8))
            )
    }
}

#Preview {
    ProBadge()
} 