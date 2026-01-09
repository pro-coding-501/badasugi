import SwiftUI

struct PowerModeSettingsSection: View {
    @ObservedObject private var powerModeManager = PowerModeManager.shared
    @AppStorage("powerModeUIFlag") private var powerModeUIFlag = false
    @AppStorage(PowerModeDefaults.autoRestoreKey) private var powerModeAutoRestoreEnabled = false
    @State private var showDisableAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.square.fill.on.square")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("파워 모드")
                        .font(.headline)
                    Text("사용 중인 앱이나 웹사이트에 따라 사용자 지정 구성을 자동으로 적용하려면 활성화하세요.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("파워 모드 활성화", isOn: toggleBinding)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            if powerModeUIFlag {
                Divider()
                    .padding(.vertical, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                
                HStack(spacing: 8) {
                    Toggle(isOn: $powerModeAutoRestoreEnabled) {
                        Text("자동 복원 기본 설정")
                    }
                    .toggleStyle(.switch)
                    
                    InfoTip(
                        title: "자동 복원 기본 설정",
                        message: "각 녹음 세션 후 향상 및 기록 기본 설정을 파워 모드가 활성화되기 전에 구성된 상태로 되돌립니다."
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: powerModeUIFlag)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(isSelected: false, useAccentGradientWhenSelected: true))
        .alert("파워 모드가 여전히 활성화됨", isPresented: $showDisableAlert) {
            Button("알겠습니다", role: .cancel) { }
        } message: {
            Text("구성이 여전히 활성화되어 있는 동안에는 파워 모드를 비활성화할 수 없습니다. 먼저 파워 모드를 비활성화하거나 제거하세요.")
        }
    }
    
    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { powerModeUIFlag },
            set: { newValue in
                if newValue {
                    powerModeUIFlag = true
                } else if powerModeManager.configurations.noneEnabled {
                    powerModeUIFlag = false
                } else {
                    showDisableAlert = true
                }
            }
        )
    }
    
}

private extension Array where Element == PowerModeConfig {
    var noneEnabled: Bool {
        allSatisfy { !$0.isEnabled }
    }
}

enum PowerModeDefaults {
    static let autoRestoreKey = "powerModeAutoRestoreEnabled"
}
