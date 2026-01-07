import SwiftUI
import AppKit

struct ClipboardManager {
    enum ClipboardError: Error {
        case copyFailed
        case accessDenied
    }

    static func setClipboard(_ text: String, transient: Bool = false) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Set the string and verify it was set correctly
        let success = pasteboard.setString(text, forType: .string)
        guard success else {
            return false
        }
        
        // Verify the clipboard content matches what we set
        let verifyDelay = DispatchTime.now() + 0.05
        DispatchQueue.main.asyncAfter(deadline: verifyDelay) {
            let clipboardContent = pasteboard.string(forType: .string)
            if clipboardContent != text {
                print("⚠️ 클립보드 검증 실패: 설정한 텍스트와 실제 클립보드 내용이 다릅니다")
            }
        }

        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            pasteboard.setString(bundleIdentifier, forType: NSPasteboard.PasteboardType("org.nspasteboard.source"))
        }

        if transient {
            pasteboard.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))
        }

        return true
    }

    static func copyToClipboard(_ text: String) -> Bool {
        return setClipboard(text, transient: false)
    }

    static func getClipboardContent() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }
}

struct ClipboardMessageModifier: ViewModifier {
    @Binding var message: String
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                            .transition(.opacity)
                            .animation(.easeInOut, value: message)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding()
            )
    }
}

extension View {
    func clipboardMessage(_ message: Binding<String>) -> some View {
        self.modifier(ClipboardMessageModifier(message: message))
    }
}
