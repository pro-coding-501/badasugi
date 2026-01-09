import SwiftUI

struct MiniRecorderView: View {
    @ObservedObject var whisperState: WhisperState
    @ObservedObject var recorder: Recorder
    @EnvironmentObject var windowManager: MiniWindowManager
    
    private var backgroundView: some View {
        ZStack {
            // 바다 컨셉 그레디언트 - 물결 같은 색상 변화
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2).opacity(0.95), // 어두운 바다색
                    Color(red: 0.1, green: 0.2, blue: 0.3).opacity(0.9),   // 중간톤 바다색
                    Color(red: 0.15, green: 0.25, blue: 0.4).opacity(0.85)  // 밝은 바다색
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // 물결 효과를 위한 추가 그레디언트
            RadialGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 80
            )

            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .opacity(0.08)
        }
        .clipShape(Capsule())
    }
    
    private var statusView: some View {
        RecorderStatusDisplay(
            currentState: whisperState.recordingState,
            audioMeter: recorder.audioMeter
        )
    }
    
    private var contentLayout: some View {
        HStack(spacing: 0) {
            // Left logo - app icon from JPG
            Image("BadasugiLogoMac")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.leading, 12)
                .shadow(color: Color.blue.opacity(0.5), radius: 4, x: 0, y: 0)

            Spacer()

            // Fixed visualizer zone
            statusView
                .frame(maxWidth: .infinity)

            Spacer()
            
            // Right spacer to balance the layout
            Color.clear
                .frame(width: 18)
                .padding(.trailing, 12)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
    
    private var recorderCapsule: some View {
        Capsule()
            .fill(.clear)
            .background(backgroundView)
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.blue.opacity(0.3),
                                Color.cyan.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay {
                contentLayout
            }
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            .shadow(color: Color.cyan.opacity(0.1), radius: 16, x: 0, y: 8)
    }
    
    var body: some View {
        Group {
            if windowManager.isVisible {
                recorderCapsule
            }
        }
    }
}
