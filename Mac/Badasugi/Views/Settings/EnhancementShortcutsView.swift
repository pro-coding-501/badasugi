import SwiftUI
import KeyboardShortcuts

struct EnhancementShortcutsView: View {
    @ObservedObject private var shortcutSettings = EnhancementShortcutSettings.shared

    var body: some View {
        VStack(spacing: 8) {
            // Toggle AI Enhancement
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 4) {
                    Text("텍스트 다듬기 토글")
                        .font(.system(size: 13))

                    InfoTip(
                        title: "텍스트 다듬기 토글",
                        message: "녹음 중에 텍스트 다듬기를 빠르게 켜거나 끕니다. 받아쓰기가 실행 중이고 녹음기가 표시되어 있을 때만 사용할 수 있습니다.",
                        learnMoreURL: "https://www.badasugi.com"
                    )
                }

                Spacer()

                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        KeyChip(label: "⌘")
                        KeyChip(label: "E")
                    }

                    Toggle("", isOn: $shortcutSettings.isToggleEnhancementShortcutEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }

            // Switch Enhancement Prompt
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 4) {
                    Text("다듬기 스타일 전환")
                        .font(.system(size: 13))

                    InfoTip(
                        title: "다듬기 스타일 전환",
                        message: "저장된 순서대로 ⌘1부터 ⌘0까지 사용하여 저장된 스타일 간에 전환합니다. 받아쓰기가 실행 중이고 녹음기가 표시되어 있을 때만 사용할 수 있습니다.",
                        learnMoreURL: "https://www.badasugi.com"
                    )
                }

                Spacer()

                HStack(spacing: 4) {
                    KeyChip(label: "⌘")
                    KeyChip(label: "1 – 0")
                }
            }
        }
        .background(Color.clear)
    }
}

// MARK: - Supporting Views
private struct KeyChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(
                        Color(NSColor.separatorColor).opacity(0.5),
                        lineWidth: 0.5
                    )
            )
    }
}
