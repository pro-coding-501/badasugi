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
    
    func toggleMiniRecorder(powerModeId: UUID? = nil) async {
        // GUARD: Prevent rapid successive calls
        if let lastTime = lastToggleMiniRecorderTime,
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
            SoundManager.shared.playStartSound()

            await MainActor.run {
                isMiniRecorderVisible = true // This will call showRecorderPanel() via didSet
            }

            await toggleRecord(powerModeId: powerModeId)
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
