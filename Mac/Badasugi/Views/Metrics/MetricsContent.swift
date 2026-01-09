import SwiftUI

struct MetricsContent: View {
    let transcriptions: [Transcription]
    let licenseState: LicenseViewModel.LicenseState
    @State private var showKeyboardShortcuts = false

    var body: some View {
        Group {
            if transcriptions.isEmpty {
                emptyStateView
            } else {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 24) {
                            heroSection
                            metricsSection
                            DashboardPromotionsSection(licenseState: licenseState)

                            Spacer(minLength: 20)

                            HStack {
                                Spacer()
                                footerActionsView
                            }
                        }
                        .frame(minHeight: geometry.size.height - 56)
                        .padding(.vertical, 28)
                        .padding(.horizontal, 32)
                    }
                    .background(Color(.windowBackgroundColor))
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 56, weight: .semibold))
                .foregroundColor(.secondary)
            Text("아직 기록이 없습니다")
                .font(.title3.weight(.semibold))
            Text("첫 녹음을 시작하여 가치 있는 인사이트를 확인하세요.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - Sections
    
    private var heroSection: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer(minLength: 0)
                
                (Text("받아쓰기로 ")
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.85))
                 +
                 Text(formattedTimeSaved)
                    .fontWeight(.black)
                    .font(.system(size: 36, design: .rounded))
                    .foregroundStyle(.white)
                 +
                 Text(" 절약했습니다")
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.85))
                )
                .font(.system(size: 30))
                .multilineTextAlignment(.center)
                
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            
            Text(heroSubtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(heroGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 30, x: 0, y: 16)
    }
    
    private var metricsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            MetricCard(
                icon: "mic.fill",
                title: "녹음 세션",
                value: "\(transcriptions.count)",
                detail: "완료된 받아쓰기 세션",
                color: .purple
            )
            
            MetricCard(
                icon: "text.alignleft",
                title: "받아쓴 단어",
                value: Formatters.formattedNumber(totalWordsTranscribed),
                detail: "생성된 단어 수",
                color: Color.accentColor
            )
            
            MetricCard(
                icon: "speedometer",
                title: "분당 단어 수",
                value: averageWordsPerMinute > 0
                    ? String(format: "%.1f", averageWordsPerMinute)
                    : "–",
                detail: "받아쓰기 vs 직접 입력",
                color: .yellow
            )
            
            MetricCard(
                icon: "keyboard.fill",
                title: "절약한 키 입력",
                value: Formatters.formattedNumber(totalKeystrokesSaved),
                detail: "더 적은 키 입력",
                color: .orange
            )
        }
    }
    
    private var footerActionsView: some View {
        HStack(spacing: 12) {
            KeyboardShortcutsButton(showKeyboardShortcuts: $showKeyboardShortcuts)
            CopySystemInfoButton()
        }
    }
    
    private var formattedTimeSaved: String {
        guard timeSaved > 0 else { return "절약 시간 계산 중" }
        
        let totalSeconds = Int(timeSaved)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        var components: [String] = []
        
        if hours > 0 {
            components.append("\(hours)시간")
        }
        if minutes > 0 {
            components.append("\(minutes)분")
        }
        if seconds > 0 || components.isEmpty {
            components.append("\(seconds)초")
        }
        
        return components.joined(separator: " ")
    }
    
    private var heroSubtitle: String {
        guard !transcriptions.isEmpty else {
            return "받아쓰기 여정은 첫 녹음으로 시작됩니다."
        }
        
        let wordsText = Formatters.formattedNumber(totalWordsTranscribed)
        let sessionCount = transcriptions.count
        let sessionText = sessionCount == 1 ? "회" : "회"
        
        return "\(sessionCount)\(sessionText)의 세션에서 \(wordsText)개의 단어를 받아썼습니다."
    }
    
    private var heroGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.accentColor,
                Color.accentColor.opacity(0.85),
                Color.accentColor.opacity(0.7)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Computed Metrics
    
    private var totalWordsTranscribed: Int {
        transcriptions.reduce(0) { $0 + $1.text.split(separator: " ").count }
    }
    
    private var totalRecordedTime: TimeInterval {
        transcriptions.reduce(0) { $0 + $1.duration }
    }
    
    private var estimatedTypingTime: TimeInterval {
        let averageTypingSpeed: Double = 35 // words per minute
        let totalWords = Double(totalWordsTranscribed)
        let estimatedTypingTimeInMinutes = totalWords / averageTypingSpeed
        return estimatedTypingTimeInMinutes * 60
    }
    
    private var timeSaved: TimeInterval {
        max(estimatedTypingTime - totalRecordedTime, 0)
    }
    
    private var averageWordsPerMinute: Double {
        guard totalRecordedTime > 0 else { return 0 }
        return Double(totalWordsTranscribed) / (totalRecordedTime / 60.0)
    }
    
    private var totalKeystrokesSaved: Int {
        Int(Double(totalWordsTranscribed) * 5.0)
    }
    
    private var firstTranscriptionDateText: String? {
        guard let firstDate = transcriptions.map(\.timestamp).min() else { return nil }
        return dateFormatter.string(from: firstDate)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

private enum Formatters {
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 2
        return formatter
    }()
    
    static func formattedNumber(_ value: Int) -> String {
        return numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    static func formattedDuration(_ interval: TimeInterval, style: DateComponentsFormatter.UnitsStyle, fallback: String = "–") -> String {
        guard interval > 0 else { return fallback }
        durationFormatter.unitsStyle = style
        durationFormatter.allowedUnits = interval >= 3600 ? [.hour, .minute] : [.minute, .second]
        return durationFormatter.string(from: interval) ?? fallback
    }
}

private struct KeyboardShortcutsButton: View {
    @Binding var showKeyboardShortcuts: Bool

    var body: some View {
        Button(action: {
            showKeyboardShortcuts = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "command")
                    .font(.system(size: 13, weight: .medium))

                Text("키보드 단축키")
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(.thinMaterial))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showKeyboardShortcuts, arrowEdge: .bottom) {
            KeyboardShortcutsListView()
        }
    }
}

private struct CopySystemInfoButton: View {
    @State private var isCopied: Bool = false

    var body: some View {
        Button(action: {
            copySystemInfo()
        }) {
            HStack(spacing: 8) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .rotationEffect(.degrees(isCopied ? 360 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopied)

                Text(isCopied ? "복사됨!" : "시스템 정보 복사")
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopied)
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(.thinMaterial))
        }
        .buttonStyle(.plain)
        .scaleEffect(isCopied ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopied)
    }

    private func copySystemInfo() {
        SystemInfoService.shared.copySystemInfoToClipboard()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isCopied = false
            }
        }
    }
}
