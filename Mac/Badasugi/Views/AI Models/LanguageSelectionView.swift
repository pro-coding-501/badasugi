import SwiftUI

// Define a display mode for flexible usage
enum LanguageDisplayMode {
    case full // For settings page with descriptions
    case menuItem // For menu bar with compact layout
}

struct LanguageSelectionView: View {
    @ObservedObject var whisperState: WhisperState
    @AppStorage("SelectedLanguage") private var selectedLanguage: String = "ko"
    // Add display mode parameter with full as the default
    var displayMode: LanguageDisplayMode = .full
    @ObservedObject var whisperPrompt: WhisperPrompt

    private func updateLanguage(_ language: String) {
        // 언어를 항상 한국어로 고정
        selectedLanguage = "ko"

        // Force the prompt to update for the new language
        whisperPrompt.updateTranscriptionPrompt()

        // Post notification for language change
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
        NotificationCenter.default.post(name: .AppSettingsDidChange, object: nil)
    }
    
    // Function to check if current model is multilingual
    private func isMultilingualModel() -> Bool {
        guard let currentModel = whisperState.currentTranscriptionModel else {
            return false
        }
        return currentModel.isMultilingualModel
    }

    private func languageSelectionDisabled() -> Bool {
        guard let provider = whisperState.currentTranscriptionModel?.provider else {
            return false
        }
        return provider == .parakeet || provider == .gemini
    }

    // Function to get current model's supported languages
    private func getCurrentModelLanguages() -> [String: String] {
        guard let currentModel = whisperState.currentTranscriptionModel else {
            return ["en": "English"] // Default to English if no model found
        }
        return currentModel.supportedLanguages
    }

    // Get the display name of the current language
    private func currentLanguageDisplayName() -> String {
        return getCurrentModelLanguages()[selectedLanguage] ?? "Unknown"
    }

    var body: some View {
        switch displayMode {
        case .full:
            fullView
        case .menuItem:
            menuItemView
        }
    }

    // The original full view layout for settings page
    private var fullView: some View {
        VStack(alignment: .leading, spacing: 16) {
            languageSelectionSection
        }
    }
    
    private var languageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("기록 언어")
                .font(.headline)

            if let currentModel = whisperState.currentTranscriptionModel
            {
                VStack(alignment: .leading, spacing: 8) {
                    Text("언어: 한국어")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text("현재 모델: \(currentModel.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("기록 언어는 한국어로 고정되어 있습니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    // 항상 한국어로 설정
                    updateLanguage("ko")
                }
            } else {
                Text("모델이 선택되지 않음")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    // New compact view for menu bar
    private var menuItemView: some View {
        Group {
            Button {
                // Do nothing, just showing info
            } label: {
                Text("언어: 한국어")
                    .foregroundColor(.secondary)
            }
            .disabled(true)
            .onAppear {
                // 항상 한국어로 설정
                updateLanguage("ko")
            }
        }
    }
}
