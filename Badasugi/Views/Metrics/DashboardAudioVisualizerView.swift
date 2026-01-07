import SwiftUI

/// Dashboard-specific audio visualizer with larger bars and status overlay.
/// Designed for the main status dashboard, separate from the compact recorder visualizer.
struct DashboardAudioVisualizerView: View {
    @StateObject private var audioInputManager = DashboardAudioInputManager.shared
    @ObservedObject var permissionManager: PermissionManager
    @EnvironmentObject private var whisperState: WhisperState
    
    // Visualizer configuration
    private let barCount = 16
    private let barSpacing: CGFloat = 4
    private let minHeight: CGFloat = 8
    private let maxHeight: CGFloat = 60
    private let barWidth: CGFloat = 6
    
    @State private var barHeights: [CGFloat] = []
    @State private var sensitivityMultipliers: [Double] = []
    
    init(permissionManager: PermissionManager) {
        self.permissionManager = permissionManager
        _barHeights = State(initialValue: Array(repeating: 8, count: 16))
        _sensitivityMultipliers = State(initialValue: (0..<16).map { _ in Double.random(in: 0.4...1.6) })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Visualizer or Permission Warning
            if permissionManager.audioPermissionStatus != .authorized {
                microphoneWarningView
            } else {
                visualizerContent
            }
            
            // Status text
            statusTextView
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(CardBackground(isSelected: false))
        .cornerRadius(16)
        .onAppear {
            if permissionManager.audioPermissionStatus == .authorized {
                audioInputManager.startMonitoring()
            }
        }
        .onDisappear {
            audioInputManager.stopMonitoring()
        }
        .onChange(of: permissionManager.audioPermissionStatus) { _, newValue in
            if newValue == .authorized {
                audioInputManager.startMonitoring()
            } else {
                audioInputManager.stopMonitoring()
            }
        }
    }
    
    // MARK: - Visualizer Content
    
    private var visualizerContent: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(barGradient)
                    .frame(width: barWidth, height: barHeights[safe: index] ?? minHeight)
            }
        }
        .frame(height: maxHeight)
        .onChange(of: audioInputManager.audioLevel) { _, newLevel in
            updateBars(with: newLevel)
        }
    }
    
    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    private func updateBars(with level: Double) {
        let range = maxHeight - minHeight
        let center = barCount / 2
        
        var newHeights: [CGFloat] = []
        
        for i in 0..<barCount {
            let distanceFromCenter = abs(i - center)
            // More variation from center to edges
            let positionMultiplier = 1.0 - (Double(distanceFromCenter) / Double(center)) * 0.6
            
            // Add some randomness for more organic movement
            let randomBoost = Double.random(in: 0.85...1.15)
            let sensitivityAdjustedLevel = level * positionMultiplier * (sensitivityMultipliers[safe: i] ?? 1.0) * randomBoost
            let targetHeight = minHeight + CGFloat(sensitivityAdjustedLevel) * range
            
            // Fast response with minimal smoothing for dynamic effect
            let currentHeight = barHeights[safe: i] ?? minHeight
            // Rising: very fast (70%), Falling: slightly slower (55%)
            let isRising = targetHeight > currentHeight
            let blendFactor = isRising ? 0.7 : 0.55
            let smoothedHeight = currentHeight * (1 - blendFactor) + targetHeight * blendFactor
            
            newHeights.append(max(minHeight, min(maxHeight, smoothedHeight)))
        }
        
        withAnimation(.easeOut(duration: 0.05)) {
            barHeights = newHeights
        }
    }
    
    // MARK: - Status Text
    
    private var statusTextView: some View {
        HStack(spacing: 8) {
            if whisperState.isModelLoading {
                ProgressView()
                    .scaleEffect(0.7)
                Text("음성 인식 준비 중...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if whisperState.currentTranscriptionModel == nil {
                Image(systemName: "waveform.badge.exclamationmark")
                    .foregroundColor(.orange)
                Text("음성 인식 모델을 선택하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if audioInputManager.isBreathing {
                Image(systemName: "waveform")
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
                Text("대기 중...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if audioInputManager.isMonitoring {
                Image(systemName: "mic.fill")
                    .foregroundColor(.accentColor)
                Text("듣는 중...")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("받아쓰기 사용 가능")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Permission Warning
    
    private var microphoneWarningView: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .symbolRenderingMode(.hierarchical)
            
            Text("마이크 권한이 필요합니다")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(action: openMicrophoneSettings) {
                Text("시스템 설정 열기")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(height: maxHeight + 20)
    }
    
    private func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Safe Array Access Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
