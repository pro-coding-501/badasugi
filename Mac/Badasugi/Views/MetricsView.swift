import SwiftUI
import SwiftData
import KeyboardShortcuts

struct MetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transcription.timestamp, order: .reverse) private var transcriptions: [Transcription]
    @EnvironmentObject private var whisperState: WhisperState
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @StateObject private var licenseViewModel = LicenseViewModel()
    @StateObject private var permissionManager = PermissionManager()
    @ObservedObject private var audioDeviceManager = AudioDeviceManager.shared
    @AppStorage("SelectedLanguage") private var selectedLanguage: String = "ko"
    @State private var isShortcutPopoverPresented = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // A) Live Audio Visualizer
                audioVisualizerSection
                
                // B) Quick Control Strip
                quickControlsSection
                
                // C) Recent Activity (Smart)
                recentActivitySection
                
                // D) System Warnings (only if needed)
                systemWarningsSection
                
                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }
    
    // MARK: - A) Live Audio Visualizer
    
    private var audioVisualizerSection: some View {
        DashboardAudioVisualizerView(permissionManager: permissionManager)
    }
    
    // MARK: - B) Quick Control Strip
    
    private var quickControlsSection: some View {
        HStack(spacing: 16) {
            // Input Source
            inputSourceControl
            
            Divider()
                .frame(height: 32)
            
            // Shortcut Info
            shortcutBadge
        }
        .padding()
        .background(CardBackground(isSelected: false))
        .cornerRadius(12)
    }
    
    private var inputSourceControl: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 14))
            
            if audioDeviceManager.availableDevices.isEmpty {
                Text("마이크 없음")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Menu {
                    ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                        Button(action: {
                            audioDeviceManager.selectInputMode(.custom)
                            audioDeviceManager.selectDevice(id: device.id)
                        }) {
                            HStack {
                                Text(device.name)
                                if audioDeviceManager.selectedDeviceID == device.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currentDeviceName)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }
    
    private var currentDeviceName: String {
        if let selectedID = audioDeviceManager.selectedDeviceID,
           let device = audioDeviceManager.availableDevices.first(where: { $0.id == selectedID }) {
            // Truncate long names
            let name = device.name
            return name.count > 20 ? String(name.prefix(18)) + "..." : name
        }
        let currentID = audioDeviceManager.getCurrentDevice()
        if let device = audioDeviceManager.availableDevices.first(where: { $0.id == currentID }) {
            let name = device.name
            return name.count > 20 ? String(name.prefix(18)) + "..." : name
        }
        return "시스템 기본"
    }
    
    private var shortcutBadge: some View {
        Button(action: {
            isShortcutPopoverPresented = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                
                Text(currentShortcutText)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.quaternaryLabelColor).opacity(0.3))
                    )
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShortcutPopoverPresented, arrowEdge: .bottom) {
            shortcutPopoverContent
        }
    }
    
    private var shortcutPopoverContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("단축키 변경")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("단축키 1")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                    
                    if hotkeyManager.selectedHotkey1 == .custom {
                        KeyboardShortcuts.Recorder(for: .toggleMiniRecorder)
                            .controlSize(.small)
                    } else {
                        Menu {
                            ForEach(HotkeyManager.HotkeyOption.allCases, id: \.self) { option in
                                Button(action: {
                                    hotkeyManager.selectedHotkey1 = option
                                }) {
                                    HStack {
                                        Text(option.displayName)
                                        if hotkeyManager.selectedHotkey1 == option {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(hotkeyManager.selectedHotkey1.displayName)
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
                
                if hotkeyManager.selectedHotkey1 != .custom {
                    Button(action: {
                        hotkeyManager.selectedHotkey1 = .custom
                    }) {
                        Label("사용자 지정 단축키 설정", systemImage: "keyboard.badge.ellipsis")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
            }
            
            Divider()
            
            Button(action: {
                isShortcutPopoverPresented = false
                NotificationCenter.default.post(
                    name: .navigateToDestination,
                    object: nil,
                    userInfo: ["destination": "Settings"]
                )
            }) {
                Label("전체 설정 열기", systemImage: "gearshape")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 280)
    }
    
    private var currentShortcutText: String {
        if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleMiniRecorder) {
            return shortcut.description
        } else if hotkeyManager.selectedHotkey1 != .none {
            return hotkeyManager.selectedHotkey1.displayName
        } else {
            return "설정 안 됨"
        }
    }
    
    // MARK: - C) Recent Activity (Smart)
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 활동")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if transcriptions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("아직 받아쓰기 기록이 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                VStack(spacing: 12) {
                    // Today's sessions
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16))
                        Text("오늘 받아쓰기")
                            .font(.subheadline)
                        Spacer()
                        Text("\(todaySessionCount)회")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    
                    Divider()
                    
                    // Keystrokes saved
                    HStack {
                        Image(systemName: "keyboard.badge.ellipsis")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16))
                        Text("절약한 타이핑")
                            .font(.subheadline)
                        Spacer()
                        Text(keystrokesSavedText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    
                    Divider()
                    
                    // Last transcription snippet
                    if let lastTranscription = transcriptions.first {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "text.quote")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 16))
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(lastTranscriptionSnippet(lastTranscription))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(3)
                                
                                Text(lastSessionTimeText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .padding(20)
        .frame(minHeight: 200)
        .background(CardBackground(isSelected: false))
        .cornerRadius(12)
    }
    
    private func lastTranscriptionSnippet(_ transcription: Transcription) -> String {
        let text = transcription.enhancedText ?? transcription.text
        if text.isEmpty {
            return "(빈 기록)"
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 60 {
            return trimmed
        }
        return String(trimmed.prefix(57)) + "..."
    }
    
    private var todaySessionCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return transcriptions.filter { transcription in
            let transcriptionDay = calendar.startOfDay(for: transcription.timestamp)
            return transcriptionDay == today
        }.count
    }
    
    private var keystrokesSavedText: String {
        let totalCharacters = transcriptions.reduce(0) { sum, transcription in
            let text = transcription.enhancedText ?? transcription.text
            return sum + text.count
        }
        
        if totalCharacters >= 10000 {
            let thousands = Double(totalCharacters) / 1000.0
            return String(format: "%.1fK타", thousands)
        } else {
            return "\(totalCharacters)타"
        }
    }
    
    private var lastSessionTimeText: String {
        guard let lastSession = transcriptions.first else { return "없음" }
        
        let now = Date()
        let interval = now.timeIntervalSince(lastSession.timestamp)
        
        // Handle edge case: very recent (within 10 seconds)
        if interval < 10 {
            return "방금 전"
        }
        
        // Handle edge case: future time (shouldn't happen, but just in case)
        if interval < 0 {
            return "방금 전"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.localizedString(for: lastSession.timestamp, relativeTo: now)
    }
    
    // MARK: - D) System Warnings
    
    @ViewBuilder
    private var systemWarningsSection: some View {
        VStack(spacing: 12) {
            // Trial warning
            if case .trial(let daysRemaining) = licenseViewModel.licenseState, daysRemaining <= 3 {
                warningCard(
                    icon: "clock.badge.exclamationmark",
                    message: "체험판이 \(daysRemaining)일 남았습니다",
                    actionLabel: "업그레이드",
                    action: {
                        NotificationCenter.default.post(
                            name: .navigateToDestination,
                            object: nil,
                            userInfo: ["destination": "받아쓰기 Pro"]
                        )
                    }
                )
            }
            
            if case .trialExpired = licenseViewModel.licenseState {
                warningCard(
                    icon: "exclamationmark.triangle.fill",
                    message: "체험판이 만료되었습니다",
                    actionLabel: "업그레이드",
                    action: {
                        NotificationCenter.default.post(
                            name: .navigateToDestination,
                            object: nil,
                            userInfo: ["destination": "받아쓰기 Pro"]
                        )
                    }
                )
            }
            
            // Permission warnings - only show if not already shown in visualizer
            if !permissionManager.isAccessibilityEnabled {
                warningCard(
                    icon: "hand.raised.slash",
                    message: "접근성 권한이 필요합니다",
                    actionLabel: "설정",
                    action: {
                        NotificationCenter.default.post(
                            name: .navigateToDestination,
                            object: nil,
                            userInfo: ["destination": "Permissions"]
                        )
                    }
                )
            }
        }
    }
    
    private func warningCard(icon: String, message: String, actionLabel: String, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: action) {
                Text(actionLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}
