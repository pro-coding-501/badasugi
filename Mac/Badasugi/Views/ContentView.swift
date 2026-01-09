import SwiftUI
import SwiftData
import KeyboardShortcuts

// ViewType enum with 3 top-level tabs
enum ViewType: String, CaseIterable, Identifiable {
    case status = "상태"
    case history = "기록"
    case settings = "설정"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .status: return "gauge.medium"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var whisperState: WhisperState
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @State private var selectedView: ViewType? = .status
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    @StateObject private var licenseViewModel = LicenseViewModel()

    private var visibleViewTypes: [ViewType] {
        ViewType.allCases
    }

    var body: some View {
        ZStack {
            // Background blur for entire window
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            if licenseViewModel.isLocked {
                // Show trial expired screen
                TrialExpiredView(licenseViewModel: licenseViewModel)
            } else {
                VStack(spacing: 0) {
                    // 상단 헤더 - More opaque material
                    HStack(spacing: 12) {
                        // 앱 로고 및 이름
                        HStack(spacing: 8) {
                            Image("BadasugiLogoMac")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .cornerRadius(6)

                            Text("받아쓰기")
                                .font(.system(size: 18, weight: .bold))

                            if case .licensed = licenseViewModel.licenseState {
                                Text("정식")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    
                    Divider()
                        .opacity(0.5)
                    
                    // 상단 탭 바 - Slightly transparent
                    GeometryReader { geometry in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(visibleViewTypes) { viewType in
                                    TopTabButton(
                                        viewType: viewType,
                                        isSelected: selectedView == viewType,
                                        action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedView = viewType
                                            }
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(minWidth: geometry.size.width)
                        }
                    }
                    .frame(height: 50)
                    .background(.thinMaterial)
                    
                    Divider()
                        .opacity(0.5)
                    
                    // 메인 컨텐츠 - Most transparent for spacious feel
                    if let selectedView = selectedView {
                        detailView(for: selectedView)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.ultraThinMaterial)
                    } else {
                        Text("항목을 선택하세요")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.ultraThinMaterial)
                    }
                }
            }
        }
        .frame(width: 950)
        .frame(minHeight: 730)
        .environmentObject(licenseViewModel)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDestination)) { notification in
            if let destination = notification.userInfo?["destination"] as? String {
                // Route to Settings tab and let SettingsContainerView handle subsection navigation
                switch destination {
                case "Settings", "AI Models", "받아쓰기 Pro", "Permissions", "Enhancement", "Power Mode",
                     "음성 인식", "텍스트 다듬기", "필수 권한", "플랜", "파워 모드", "사용 방식":
                    selectedView = .settings
                default:
                    break
                }
                // Forward the notification so SettingsContainerView can handle subsection
            }
        }
    }
    
    @ViewBuilder
    private func detailView(for viewType: ViewType) -> some View {
        switch viewType {
        case .status:
            MetricsView()
        case .history:
            TranscriptionHistoryView()
        case .settings:
            SettingsContainerView()
                .environmentObject(whisperState)
        }
    }
}

// 상단 탭 버튼
private struct TopTabButton: View {
    let viewType: ViewType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: viewType.icon)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(viewType.rawValue)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                }
                .fixedSize(horizontal: true, vertical: false)
                .foregroundColor(isSelected ? Color.accentColor : Color.primary.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                )
            }
        }
        .buttonStyle(.plain)
    }
}

