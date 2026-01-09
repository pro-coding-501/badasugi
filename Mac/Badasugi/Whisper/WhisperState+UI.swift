import Foundation
import SwiftUI
import os

// MARK: - UI Management Extension
extension WhisperState {
    
    // MARK: - Recorder Panel Management
    
    func showRecorderPanel() {
        logger.notice("📱 Showing mini recorder")
        
        // Clean up any existing recorder
        miniWindowManager?.forceHide()
        miniWindowManager = nil
        
        // Always use mini recorder
        let manager = MiniWindowManager(whisperState: self, recorder: recorder)
        miniWindowManager = manager
        manager.show()
    }
    
    func hideRecorderPanel() {
        // Hide and destroy mini recorder
        miniWindowManager?.forceHide()
        miniWindowManager = nil
    }
    
    // MARK: - Mini Recorder Management
    
    func toggleMiniRecorder(powerModeId: UUID? = nil, bypassCooldown: Bool = false) async {
        // GUARD: Check license/trial status first
        if licenseViewModel.isLocked {
            logger.warning("⚠️ Trial expired - recording blocked")
            await MainActor.run {
                showTrialExpiredAlert()
            }
            return
        }
        
        // GUARD: Check if enhancementService is available (required for recorder UI)
        guard enhancementService != nil else {
            logger.warning("⚠️ enhancementService is nil - cannot start recording")
            return
        }
        
        // GUARD: Check if a transcription model is selected
        guard currentTranscriptionModel != nil else {
            logger.warning("⚠️ No transcription model selected - cannot start recording")
            await MainActor.run {
                NotificationManager.shared.showNotification(
                    title: "AI 모델이 선택되지 않았습니다",
                    type: .error
                )
            }
            return
        }
        
        // Determine whether this invocation is intended to STOP an ongoing recording.
        // Push-to-Talk triggers start on keyDown and stop on keyUp, which can happen faster than the
        // default cooldown; stopping should remain responsive.
        let isStopAction = isMiniRecorderVisible && recordingState == .recording

        // GUARD: Prevent rapid successive calls (but never block a stop action, and allow explicit bypass)
        if !bypassCooldown && !isStopAction,
           let lastTime = lastToggleMiniRecorderTime,
           Date().timeIntervalSince(lastTime) < toggleMiniRecorderCooldown {
            logger.warning("⚠️ toggleMiniRecorder called too quickly, ignoring (cooldown)")
            return
        }
        
        // GUARD: Prevent concurrent calls  
        if isToggleMiniRecorderProcessing {
            logger.warning("⚠️ toggleMiniRecorder already processing, ignoring")
            return
        }
        
        isToggleMiniRecorderProcessing = true
        lastToggleMiniRecorderTime = Date()
        defer { isToggleMiniRecorderProcessing = false }
        
        if isMiniRecorderVisible {
            if recordingState == .recording {
                await toggleRecord(powerModeId: powerModeId)
            } else {
                await cancelRecording()
            }
        } else {
            // Play start sound first
            SoundManager.shared.playStartSound()
            
            // Wait for sound to start playing before initializing audio engine
            // This prevents audio subsystem conflicts that can cause kernel panic
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms delay

            await MainActor.run {
                isMiniRecorderVisible = true // This will call showRecorderPanel() via didSet
            }

            await toggleRecord(powerModeId: powerModeId)
        }
    }
    
    private func showTrialExpiredAlert() {
        let alert = NSAlert()
        alert.messageText = "체험 기간이 만료되었습니다"
        alert.informativeText = "받아쓰기의 모든 기능을 계속 사용하려면 라이선스를 구매하거나 활성화해주세요."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "설정 열기")
        alert.addButton(withTitle: "나중에")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Navigate to settings/plan tab
            NotificationCenter.default.post(
                name: .navigateToDestination,
                object: nil,
                userInfo: ["destination": "플랜"]
            )
            // Activate the app window
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func dismissMiniRecorder() async {
        if recordingState == .busy { return }

        let wasRecording = recordingState == .recording
 
        await MainActor.run {
            self.recordingState = .busy
        }
        
        if wasRecording {
            await recorder.stopRecording()
        }
        
        hideRecorderPanel()
        
        // Clear captured context when the recorder is dismissed
        if let enhancementService = enhancementService {
            await MainActor.run {
                enhancementService.clearCapturedContexts()
            }
        }
        
        await MainActor.run {
            isMiniRecorderVisible = false
        }
        
        await cleanupModelResources()
        
        if UserDefaults.standard.bool(forKey: PowerModeDefaults.autoRestoreKey) {
            await PowerModeSessionManager.shared.endSession()
            await MainActor.run {
                PowerModeManager.shared.setActiveConfiguration(nil)
            }
        }
        
        await MainActor.run {
            recordingState = .idle
        }
    }
    
    func resetOnLaunch() async {
        logger.notice("🔄 Resetting recording state on launch")
        await recorder.stopRecording()
        hideRecorderPanel()
        await MainActor.run {
            isMiniRecorderVisible = false
            shouldCancelRecording = false
            miniRecorderError = nil
            recordingState = .idle
        }
        await cleanupModelResources()
    }
    
    func cancelRecording() async {
        SoundManager.shared.playEscSound()
        shouldCancelRecording = true
        await dismissMiniRecorder()
    }
    
    // MARK: - Notification Handling
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleToggleMiniRecorder), name: .toggleMiniRecorder, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDismissMiniRecorder), name: .dismissMiniRecorder, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLicenseStatusChanged), name: .licenseStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePromptChange), name: .promptDidChange, object: nil)
    }
    
    @objc public func handleToggleMiniRecorder() {
        Task {
            await toggleMiniRecorder()
        }
    }
    
    @objc public func handleDismissMiniRecorder() {
        Task {
            await dismissMiniRecorder()
        }
    }
    
    @objc func handleLicenseStatusChanged() {
        self.licenseViewModel = LicenseViewModel()
    }
    
    @objc func handlePromptChange() {
        // Update the whisper context with the new prompt
        Task {
            await updateContextPrompt()
        }
    }
    
    private func updateContextPrompt() async {
        // Always reload the prompt from UserDefaults to ensure we have the latest
        let currentPrompt = UserDefaults.standard.string(forKey: "TranscriptionPrompt") ?? whisperPrompt.transcriptionPrompt
        
        if let context = whisperContext {
            await context.setPrompt(currentPrompt)
        }
    }
} 
