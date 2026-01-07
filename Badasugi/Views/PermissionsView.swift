import SwiftUI
import AVFoundation
import Cocoa
import KeyboardShortcuts

class PermissionManager: ObservableObject {
    @Published var audioPermissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    @Published var isAccessibilityEnabled = false
    @Published var isScreenRecordingEnabled = false
    @Published var isKeyboardShortcutSet = false
    
    init() {
        setupNotificationObservers()
        checkAllPermissions()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidBecomeActive() {
        checkAllPermissions()
    }
    
    func checkAllPermissions() {
        checkAccessibilityPermissions()
        checkScreenRecordingPermission()
        checkAudioPermissionStatus()
        checkKeyboardShortcut()
    }
    
    func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.async {
            self.isAccessibilityEnabled = accessibilityEnabled
        }
    }
    
    func checkScreenRecordingPermission() {
        DispatchQueue.main.async {
            self.isScreenRecordingEnabled = CGPreflightScreenCaptureAccess()
        }
    }
    
    func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }
    
    func checkAudioPermissionStatus() {
        DispatchQueue.main.async {
            self.audioPermissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        }
    }
    
    func requestAudioPermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                self.audioPermissionStatus = granted ? .authorized : .denied
            }
        }
    }
    
    func checkKeyboardShortcut() {
        DispatchQueue.main.async {
            self.isKeyboardShortcutSet = KeyboardShortcuts.getShortcut(for: .toggleMiniRecorder) != nil
        }
    }
}

// Native list style permission row
struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    let checkPermission: () -> Void
    var infoTipTitle: String?
    var infoTipMessage: String?
    var infoTipLink: String?
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: isGranted ? "\(icon).fill" : icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isGranted ? .green : .secondary)
                    .frame(width: 24)
                
                // Title and description
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                        
                        if let infoTipTitle = infoTipTitle, let infoTipMessage = infoTipMessage {
                            InfoTip(
                                title: infoTipTitle,
                                message: infoTipMessage,
                                learnMoreURL: infoTipLink ?? ""
                            )
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isRefreshing = true
                    }
                    checkPermission()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isRefreshing = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                }
                .buttonStyle(.plain)
                
                // Status / Action
                if isGranted {
                    Text("완료")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    Button(action: action) {
                        Text("설정")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
        }
    }
}

struct PermissionsView: View {
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @StateObject private var permissionManager = PermissionManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Left-aligned header
                Text("필수 권한")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Permission list
                VStack(spacing: 0) {
                    // Keyboard Shortcut
                    PermissionRow(
                        icon: "keyboard",
                        title: "키보드 단축키",
                        description: "어디서나 받아쓰기를 시작할 수 있습니다",
                        isGranted: hotkeyManager.selectedHotkey1 != .none,
                        action: {
                            NotificationCenter.default.post(
                                name: .navigateToDestination,
                                object: nil,
                                userInfo: ["destination": "Settings"]
                            )
                        },
                        checkPermission: { permissionManager.checkKeyboardShortcut() }
                    )
                    
                    Divider().padding(.leading, 40)
                    
                    // Microphone
                    PermissionRow(
                        icon: "mic",
                        title: "마이크 접근",
                        description: "음성을 녹음하여 텍스트로 변환합니다",
                        isGranted: permissionManager.audioPermissionStatus == .authorized,
                        action: {
                            if permissionManager.audioPermissionStatus == .notDetermined {
                                permissionManager.requestAudioPermission()
                            } else {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        },
                        checkPermission: { permissionManager.checkAudioPermissionStatus() }
                    )
                    
                    Divider().padding(.leading, 40)
                    
                    // Accessibility
                    PermissionRow(
                        icon: "hand.raised",
                        title: "접근성 접근",
                        description: "받아쓴 텍스트를 커서 위치에 입력합니다",
                        isGranted: permissionManager.isAccessibilityEnabled,
                        action: {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        },
                        checkPermission: { permissionManager.checkAccessibilityPermissions() },
                        infoTipTitle: "접근성 접근",
                        infoTipMessage: "받아쓰기는 받아쓴 텍스트를 앱의 커서 위치에 직접 입력하기 위해 접근성 권한이 필요합니다."
                    )
                    
                    Divider().padding(.leading, 40)
                    
                    // Screen Recording
                    PermissionRow(
                        icon: "rectangle.on.rectangle",
                        title: "화면 녹화 접근",
                        description: "화면 내용을 참고하여 더 정확하게 인식합니다",
                        isGranted: permissionManager.isScreenRecordingEnabled,
                        action: {
                            permissionManager.requestScreenRecordingPermission()
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                                NSWorkspace.shared.open(url)
                            }
                        },
                        checkPermission: { permissionManager.checkScreenRecordingPermission() },
                        infoTipTitle: "화면 녹화 접근",
                        infoTipMessage: "화면의 텍스트를 참고하면 받아쓰기 정확도가 높아집니다. 데이터는 저장되지 않습니다."
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }
}

#Preview {
    PermissionsView()
}
