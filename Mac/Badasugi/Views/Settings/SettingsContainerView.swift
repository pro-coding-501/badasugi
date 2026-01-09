import SwiftUI

// Settings subsection types
enum SettingsSubsection: String, CaseIterable, Identifiable {
    case usage = "사용 방식"
    case speechRecognition = "음성 인식"
    case textEnhancement = "텍스트 다듬기"
    case accuracy = "정확도 향상"
    case microphone = "마이크"
    case permissions = "필수 권한"
    case plan = "플랜"
    case powerMode = "파워 모드"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .usage: return "command.circle.fill"
        case .speechRecognition: return "waveform.circle.fill"
        case .textEnhancement: return "wand.and.stars"
        case .accuracy: return "text.badge.checkmark"
        case .microphone: return "mic.fill"
        case .permissions: return "shield.fill"
        case .plan: return "checkmark.seal.fill"
        case .powerMode: return "sparkles.square.fill.on.square"
        }
    }
}

struct SettingsContainerView: View {
    @EnvironmentObject private var whisperState: WhisperState
    @AppStorage("powerModeUIFlag") private var powerModeUIFlag = false
    @State private var selectedSubsection: SettingsSubsection = .usage
    
    private var visibleSubsections: [SettingsSubsection] {
        SettingsSubsection.allCases.filter { subsection in
            if subsection == .powerMode {
                return powerModeUIFlag
            }
            return true
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left sidebar with subsection list
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(visibleSubsections) { subsection in
                        SettingsSubsectionRow(
                            subsection: subsection,
                            isSelected: selectedSubsection == subsection,
                            action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedSubsection = subsection
                                }
                            }
                        )
                    }
                }
                .padding(14)
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content area
            subsectionContent(for: selectedSubsection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDestination)) { notification in
            if let destination = notification.userInfo?["destination"] as? String {
                switch destination {
                case "Settings", "사용 방식":
                    selectedSubsection = .usage
                case "AI Models", "음성 인식":
                    selectedSubsection = .speechRecognition
                case "Enhancement", "텍스트 다듬기":
                    selectedSubsection = .textEnhancement
                case "Permissions", "필수 권한":
                    selectedSubsection = .permissions
                case "받아쓰기 Pro", "플랜":
                    selectedSubsection = .plan
                case "Power Mode", "파워 모드":
                    selectedSubsection = .powerMode
                default:
                    break
                }
            }
        }
    }
    
    @ViewBuilder
    private func subsectionContent(for subsection: SettingsSubsection) -> some View {
        switch subsection {
        case .usage:
            SettingsView()
                .environmentObject(whisperState)
        case .speechRecognition:
            ModelManagementView(whisperState: whisperState)
        case .textEnhancement:
            EnhancementSettingsView()
        case .accuracy:
            DictionarySettingsView(whisperPrompt: whisperState.whisperPrompt)
        case .microphone:
            AudioInputSettingsView()
        case .permissions:
            PermissionsView()
        case .plan:
            LicenseManagementView()
        case .powerMode:
            PowerModeView()
        }
    }
}

// Settings subsection row
private struct SettingsSubsectionRow: View {
    let subsection: SettingsSubsection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: subsection.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 26)
                
                Text(subsection.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
