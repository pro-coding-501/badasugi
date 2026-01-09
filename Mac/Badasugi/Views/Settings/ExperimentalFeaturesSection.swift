import SwiftUI

struct ExperimentalFeaturesSection: View {
    @AppStorage("isExperimentalFeaturesEnabled") private var isExperimentalFeaturesEnabled = false
    @ObservedObject private var playbackController = PlaybackController.shared
    @ObservedObject private var mediaController = MediaController.shared
    @State private var expandedSections: Set<ExpandableSection> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "flask")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("실험적 기능")
                        .font(.headline)
                    Text("불안정하고 약간 버그가 있을 수 있는 실험적 기능입니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("실험적 기능", isOn: $isExperimentalFeaturesEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .onChange(of: isExperimentalFeaturesEnabled) { _, newValue in
                        if !newValue {
                            playbackController.isPauseMediaEnabled = false
                        }
                    }
            }

            if isExperimentalFeaturesEnabled {
                Divider()
                    .padding(.vertical, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                ExpandableToggleSection(
                    section: .pauseMedia,
                    title: "녹음 중 미디어 일시 정지",
                    helpText: "녹음 중 활성 미디어 재생을 자동으로 일시 정지하고 이후 재개합니다.",
                    isEnabled: $playbackController.isPauseMediaEnabled,
                    expandedSections: $expandedSections
                ) {
                    HStack(spacing: 8) {
                        Text("재개 지연")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("", selection: $mediaController.audioResumptionDelay) {
                            Text("0초").tag(0.0)
                            Text("1초").tag(1.0)
                            Text("2초").tag(2.0)
                            Text("3초").tag(3.0)
                            Text("4초").tag(4.0)
                            Text("5초").tag(5.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)

                        InfoTip(
                            title: "오디오 재개 지연",
                            message: "녹음 중지 후 미디어 재생을 재개하기 전 지연 시간입니다. 마이크 모드에서 고품질 오디오 모드로 전환하는 데 시간이 필요한 블루투스 헤드폰에 유용합니다. 권장: AirPods/블루투스 헤드폰 2초, 유선 헤드폰 0초."
                        )

                        Spacer()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExperimentalFeaturesEnabled)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(isSelected: false, useAccentGradientWhenSelected: true))
    }
}
