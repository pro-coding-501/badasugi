import SwiftUI
import AVFoundation
import AppKit
import KeyboardShortcuts

struct OnboardingPermission: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let type: PermissionType
    
    enum PermissionType {
        case microphone
        case audioDeviceSelection
        case accessibility
        case screenRecording
        case keyboardShortcut
        
        var systemName: String {
            switch self {
            case .microphone: return "mic"
            case .audioDeviceSelection: return "headphones"
            case .accessibility: return "accessibility"
            case .screenRecording: return "rectangle.inset.filled.and.person.filled"
            case .keyboardShortcut: return "keyboard"
            }
        }
    }
}

struct OnboardingPermissionsView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @ObservedObject private var audioDeviceManager = AudioDeviceManager.shared
    @State private var permissionStates: [Bool] = [false, false, false, false, false]
    @State private var showModelDownload = false
    @State private var permissionCheckTimer: Timer?
    
    private let permissions: [OnboardingPermission] = [
        OnboardingPermission(
            title: "마이크 권한",
            description: "마이크 권한을 허용하여 음성을 텍스트로 즉시 변환할 수 있습니다.",
            icon: "waveform",
            type: .microphone
        ),
        OnboardingPermission(
            title: "마이크 선택",
            description: "받아쓰기에서 사용할 오디오 입력 장치를 선택하세요.",
            icon: "headphones",
            type: .audioDeviceSelection
        ),
        OnboardingPermission(
            title: "접근성 권한",
            description: "받아쓰기가 Mac 어디서나 입력을 도울 수 있도록 허용하세요.",
            icon: "accessibility",
            type: .accessibility
        ),
        OnboardingPermission(
            title: "화면 녹화 권한",
            description: "화면의 텍스트를 분석하여 음성 인식 정확도를 향상시킵니다.",
            icon: "rectangle.inset.filled.and.person.filled",
            type: .screenRecording
        ),
        OnboardingPermission(
            title: "키보드 단축키",
            description: "어디서나 받아쓰기에 빠르게 접근할 수 있도록 키보드 단축키를 설정하세요.",
            icon: "keyboard",
            type: .keyboardShortcut
        )
    ]
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    // Reusable background
                    OnboardingBackgroundView()
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            // Title
                            VStack(spacing: 8) {
                                Text("권한 설정")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("받아쓰기를 사용하기 위해 필요한 권한을 설정해주세요")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.bottom, 12)
                            
                            // All permissions list
                            VStack(spacing: 10) {
                                ForEach(Array(permissions.enumerated()), id: \.element.id) { index, permission in
                                    permissionCard(
                                        permission: permission,
                                        index: index,
                                        isGranted: permissionStates[index]
                                    )
                                }
                            }
                            .padding(.horizontal, 40)
                            
                            // Continue button
                            Button(action: {
                                withAnimation {
                                    showModelDownload = true
                                }
                            }) {
                                Text("계속하기")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 200, height: 44)
                                    .background(Color.accentColor)
                                    .cornerRadius(22)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.top, 12)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            if showModelDownload {
                OnboardingModelDownloadView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onAppear {
            checkExistingPermissions()
            // Ensure audio devices are loaded
            audioDeviceManager.loadAvailableDevices()
            
            // 주기적으로 권한 상태 확인 (시스템 설정에서 변경한 경우 대비)
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                checkExistingPermissions()
            }
        }
        .onDisappear {
            // Timer 정리 - 메모리 누수 및 충돌 방지
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
        }
    }
    
    @ViewBuilder
    private func permissionCard(permission: OnboardingPermission, index: Int, isGranted: Bool) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isGranted ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                if isGranted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: permission.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                }
            }
            
            // Title and description
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(permission.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    if permission.type == .screenRecording {
                        InfoTip(
                            title: "화면 녹화 권한",
                            message: "받아쓰기는 화면의 텍스트를 캡처하여 음성 입력의 컨텍스트를 이해하며, 이를 통해 기록 정확도가 크게 향상됩니다. 개인정보 보호가 중요합니다: 이 데이터는 로컬에서 처리되며 저장되지 않습니다.",
                            learnMoreURL: "https://www.badasugi.com"
                        )
                    }
                }
                
                Text(permission.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Action button
            if permission.type == .audioDeviceSelection {
                // Audio device picker
                if audioDeviceManager.availableDevices.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: "mic.slash.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))
                        Text("마이크 없음")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    Menu {
                        ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                            Button(action: {
                                audioDeviceManager.selectDevice(id: device.id)
                                audioDeviceManager.selectInputMode(.custom)
                                withAnimation {
                                    permissionStates[index] = true
                                }
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
                        HStack(spacing: 6) {
                            Text(audioDeviceManager.availableDevices.first { $0.id == audioDeviceManager.selectedDeviceID }?.name ?? "장치 선택")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .onAppear {
                        if !audioDeviceManager.availableDevices.isEmpty && audioDeviceManager.selectedDeviceID == nil {
                            if let deviceID = audioDeviceManager.findBestAvailableDevice() {
                                audioDeviceManager.selectDevice(id: deviceID)
                                audioDeviceManager.selectInputMode(.custom)
                                withAnimation {
                                    permissionStates[index] = true
                                }
                            }
                        }
                    }
                }
            } else if permission.type == .keyboardShortcut {
                // Keyboard shortcut picker
                VStack(spacing: 8) {
                    Menu {
                        ForEach(HotkeyManager.HotkeyOption.allCases.filter { $0 != .none && $0 != .custom }, id: \.self) { option in
                            Button(action: {
                                hotkeyManager.selectedHotkey1 = option
                                withAnimation {
                                    permissionStates[index] = option != .none
                                }
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
                        Button(action: {
                            hotkeyManager.selectedHotkey1 = .custom
                            withAnimation {
                                permissionStates[index] = false
                            }
                        }) {
                            HStack {
                                Text("커스텀")
                                if hotkeyManager.selectedHotkey1 == .custom {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(hotkeyManager.selectedHotkey1.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    if hotkeyManager.selectedHotkey1 == .custom {
                        KeyboardShortcuts.Recorder(for: .toggleMiniRecorder) { newShortcut in
                            withAnimation {
                                permissionStates[index] = newShortcut != nil
                            }
                        }
                        .controlSize(.regular)
                    }
                }
                .onChange(of: hotkeyManager.selectedHotkey1) { newValue in
                    if newValue != .custom {
                        withAnimation {
                            permissionStates[index] = newValue != .none
                        }
                    }
                }
            } else {
                // Permission request button
                Button(action: {
                    requestPermission(for: index)
                }) {
                    HStack(spacing: 6) {
                        if isGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                        }
                        Text(isGranted ? "완료" : "설정")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isGranted ? Color.green.opacity(0.2) : Color.accentColor)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isGranted ? Color.green : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGranted ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func checkExistingPermissions() {
        // Check microphone permission
        permissionStates[0] = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        
        // Check if device is selected
        permissionStates[1] = audioDeviceManager.selectedDeviceID != nil
        
        // Check accessibility permission
        permissionStates[2] = AXIsProcessTrusted()
        
        // Check screen recording permission
        permissionStates[3] = CGPreflightScreenCaptureAccess()
        
        // Check keyboard shortcut
        permissionStates[4] = hotkeyManager.isShortcutConfigured
    }
    
    private func requestPermission(for index: Int) {
        if permissionStates[index] {
            return
        }
        
        switch permissions[index].type {
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    self.permissionStates[index] = granted
                    if granted {
                        self.audioDeviceManager.loadAvailableDevices()
                        // 마이크 권한이 허용되면 자동으로 최적의 장치 선택
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let deviceID = self.audioDeviceManager.findBestAvailableDevice() {
                                self.audioDeviceManager.selectDevice(id: deviceID)
                                self.audioDeviceManager.selectInputMode(.custom)
                                withAnimation {
                                    self.permissionStates[1] = true
                                }
                            }
                        }
                    }
                }
            }
            
        case .accessibility:
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options)
            
            // Start checking for permission status
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                if AXIsProcessTrusted() {
                    timer.invalidate()
                    DispatchQueue.main.async {
                        withAnimation {
                            self.permissionStates[index] = true
                        }
                    }
                }
            }
            
        case .screenRecording:
            // First try to request permission programmatically
            CGRequestScreenCaptureAccess()
            
            // Also open system preferences as fallback
            if let prefpaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(prefpaneURL)
            }
            
            // Start checking for permission status
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                if CGPreflightScreenCaptureAccess() {
                    timer.invalidate()
                    DispatchQueue.main.async {
                        withAnimation {
                            self.permissionStates[index] = true
                        }
                    }
                }
            }
            
        default:
            break
        }
    }

}
