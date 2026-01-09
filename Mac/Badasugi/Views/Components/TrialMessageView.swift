import SwiftUI

struct TrialMessageView: View {
    let message: String
    let type: MessageType
    var onAddLicenseKey: (() -> Void)? = nil
    
    enum MessageType {
        case warning
        case expired
        case info
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    onAddLicenseKey?()
                }) {
                    Text("라이선스 입력")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.bordered)

                Button(action: {
                    if let url = URL(string: "https://www.badasugi.com") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("라이선스 구매")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }
    
    private var icon: String {
        switch type {
        case .warning: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .warning: return .orange
        case .expired: return .red
        case .info: return .accentColor
        }
    }
    
    private var title: String {
        switch type {
        case .warning: return "체험판 곧 종료"
        case .expired: return "체험판 만료"
        case .info: return "체험판 활성"
        }
    }
    
    private var backgroundColor: Color {
        switch type {
        case .warning: return Color.orange.opacity(0.1)
        case .expired: return Color.red.opacity(0.1)
        case .info: return Color.accentColor.opacity(0.1)
        }
    }
} 