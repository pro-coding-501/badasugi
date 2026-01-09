import SwiftUI

struct HelpAndResourcesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("도움말 및 리소스")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))

            VStack(alignment: .leading, spacing: 10) {
                resourceLink(
                    icon: "sparkles",
                    title: "추천 모델",
                    url: "https://www.badasugi.com"
                )

                resourceLink(
                    icon: "video.fill",
                    title: "YouTube 동영상 및 가이드",
                    url: "https://www.youtube.com/@badasugi"
                )

                resourceLink(
                    icon: "book.fill",
                    title: "문서",
                    url: "https://www.badasugi.com"
                )
                
                resourceLink(
                    icon: "exclamationmark.bubble.fill",
                    title: "피드백 또는 문제가 있나요?",
                    action: {
                        EmailSupport.openSupportEmail()
                    }
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func resourceLink(icon: String, title: String, url: String? = nil, action: (() -> Void)? = nil) -> some View {
        Button(action: {
            if let action = action {
                action()
            } else if let urlString = url, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

        }
        .buttonStyle(.plain)
    }
}
