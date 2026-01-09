import Foundation
import AppKit
import os.log

class CursorPaster {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Badasugi", category: "CursorPaster")

    static func pasteAtCursor(_ text: String) -> Bool {
        // Check accessibility permission first
        guard AXIsProcessTrusted() else {
            logger.error("접근성 권한이 없어 붙여넣기를 수행할 수 없습니다")
            DispatchQueue.main.async {
                NotificationManager.shared.showNotification(
                    title: "접근성 권한 필요",
                    type: .error,
                    duration: 5.0,
                    onTap: {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
            }
            // Still copy to clipboard as fallback
            ClipboardManager.setClipboard(text, transient: false)
            return false
        }

        let pasteboard = NSPasteboard.general
        let shouldRestoreClipboard = UserDefaults.standard.bool(forKey: "restoreClipboardAfterPaste")

        var savedContents: [(NSPasteboard.PasteboardType, Data)] = []

        if shouldRestoreClipboard {
            let currentItems = pasteboard.pasteboardItems ?? []

            for item in currentItems {
                for type in item.types {
                    if let data = item.data(forType: type) {
                        savedContents.append((type, data))
                    }
                }
            }
        }

        let clipboardSet = ClipboardManager.setClipboard(text, transient: shouldRestoreClipboard)
        guard clipboardSet else {
            logger.error("클립보드에 텍스트를 설정하는데 실패했습니다")
            DispatchQueue.main.async {
                NotificationManager.shared.showNotification(
                    title: "붙여넣기 실패",
                    type: .error
                )
            }
            return false
        }

        // Verify clipboard was set correctly
        let verifyDelay = DispatchTime.now() + 0.1
        DispatchQueue.main.asyncAfter(deadline: verifyDelay) {
            let clipboardContent = NSPasteboard.general.string(forType: .string)
            if clipboardContent != text {
                logger.error("클립보드 검증 실패. 예상: '\(text.prefix(50), privacy: .public)', 실제: '\(clipboardContent?.prefix(50) ?? "nil", privacy: .public)'")
                DispatchQueue.main.async {
                    NotificationManager.shared.showNotification(
                        title: "클립보드 설정 실패. 수동으로 붙여넣기(Cmd+V)를 사용하세요.",
                        type: .warning,
                        duration: 5.0
                    )
                }
                return
            }
            
            logger.info("클립보드 검증 성공. 텍스트 길이: \(text.count)")
            
            // Paste after verification
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let success: Bool
                if UserDefaults.standard.bool(forKey: "UseAppleScriptPaste") {
                    logger.info("AppleScript 방식으로 붙여넣기 시도")
                    success = pasteUsingAppleScript()
                } else {
                    logger.info("CGEvent 방식으로 붙여넣기 시도")
                    success = pasteUsingCommandV()
                }
                
                if !success {
                    logger.error("붙여넣기 명령 실행 실패")
                    DispatchQueue.main.async {
                        NotificationManager.shared.showNotification(
                            title: "붙여넣기 실패. 클립보드에 복사되었으니 수동으로 붙여넣기(Cmd+V)를 사용하세요.",
                            type: .warning,
                            duration: 5.0
                        )
                    }
                } else {
                    logger.info("붙여넣기 명령 실행 성공")
                }
            }
        }

        if shouldRestoreClipboard {
            let restoreDelay = UserDefaults.standard.double(forKey: "clipboardRestoreDelay")
            let delay = restoreDelay > 0 ? restoreDelay : 1.5

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if !savedContents.isEmpty {
                    pasteboard.clearContents()
                    for (type, data) in savedContents {
                        pasteboard.setData(data, forType: type)
                    }
                }
            }
        }
        
        return true
    }
    
    private static func pasteUsingAppleScript() -> Bool {
        guard AXIsProcessTrusted() else {
            logger.error("접근성 권한이 없어 AppleScript로 붙여넣기를 수행할 수 없습니다")
            return false
        }
        
        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            _ = scriptObject.executeAndReturnError(&error)
            if let error = error {
                logger.error("AppleScript 실행 실패: \(error.description, privacy: .public)")
                return false
            }
            logger.info("AppleScript로 Command+V 실행 완료")
            return true
        }
        logger.error("NSAppleScript 객체를 생성할 수 없습니다")
        return false
    }
    
    private static func pasteUsingCommandV() -> Bool {
        guard AXIsProcessTrusted() else {
            logger.error("접근성 권한이 없어 Command+V를 시뮬레이션할 수 없습니다")
            return false
        }
        
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            logger.error("CGEventSource를 생성할 수 없습니다")
            return false
        }
        
        // Get the currently active application for debugging
        if let activeApp = NSWorkspace.shared.frontmostApplication {
            logger.info("활성 앱: \(activeApp.localizedName ?? "알 수 없음")")
        }
        
        let tapLocation: CGEventTapLocation = .cghidEventTap
        
        // Create only V key events with Command flag - no separate Command key events
        guard let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            logger.error("키보드 이벤트를 생성할 수 없습니다")
            return false
        }
        
        // Set Command flag on V key events - this simulates Cmd+V without separate modifier key events
        vDown.flags = .maskCommand
        vUp.flags = []  // No modifier on key-up to prevent double paste
        
        // Post only the V key events
        vDown.post(tap: tapLocation)
        Thread.sleep(forTimeInterval: 0.02) // 20ms delay for reliability
        vUp.post(tap: tapLocation)
        
        logger.info("Command+V 이벤트 전송 완료")
        return true
    }

    // Simulate pressing the Return / Enter key
    static func pressEnter() {
        guard AXIsProcessTrusted() else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let enterDown = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true)
        let enterUp = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false)
        enterDown?.post(tap: .cghidEventTap)
        enterUp?.post(tap: .cghidEventTap)
    }
}
