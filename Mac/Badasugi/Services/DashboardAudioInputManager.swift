import Foundation
import AVFoundation
import CoreAudio
import os

/// Manager for real-time microphone monitoring on the dashboard.
/// This is separate from the recording Recorder class - it only monitors audio levels
/// without recording to a file.
@MainActor
class DashboardAudioInputManager: ObservableObject {
    private let logger = Logger(subsystem: "com.badasugi.app", category: "DashboardAudioInputManager")
    
    // MARK: - Published Properties
    @Published var audioLevel: Double = 0.0
    @Published var isMonitoring: Bool = false
    @Published var hasMicrophonePermission: Bool = false
    @Published var isBreathing: Bool = false
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var silenceTimer: Timer?
    private let deviceManager = AudioDeviceManager.shared
    
    // Breathing animation state
    private var breathingPhase: Double = 0.0
    private var breathingTimer: Timer?
    
    // Constants
    private let silenceThreshold: Double = 0.02
    private let silenceDelay: TimeInterval = 2.0
    
    // MARK: - Singleton
    static let shared = DashboardAudioInputManager()
    
    private init() {
        checkMicrophonePermission()
    }
    
    // MARK: - Permission Handling
    
    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            hasMicrophonePermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor in
                    self?.hasMicrophonePermission = granted
                }
            }
        case .denied, .restricted:
            hasMicrophonePermission = false
        @unknown default:
            hasMicrophonePermission = false
        }
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        guard hasMicrophonePermission else {
            logger.warning("Cannot start monitoring: microphone permission denied")
            return
        }
        
        // Don't monitor if recording is active (to avoid conflicts)
        guard !deviceManager.isRecordingActive else {
            logger.info("Skipping dashboard monitoring: recording is active")
            return
        }
        
        do {
            let engine = AVAudioEngine()
            audioEngine = engine
            
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            
            // Install a tap to read audio levels
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }
            
            try engine.start()
            isMonitoring = true
            logger.info("Dashboard audio monitoring started")
            
            // Start breathing animation timer
            startBreathingAnimation()
            
        } catch {
            logger.error("Failed to start audio monitoring: \(error.localizedDescription)")
            stopMonitoring()
        }
    }
    
    func stopMonitoring() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        
        isMonitoring = false
        audioLevel = 0.0
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        breathingTimer?.invalidate()
        breathingTimer = nil
        isBreathing = false
        
        logger.info("Dashboard audio monitoring stopped")
    }
    
    // MARK: - Audio Processing
    
    nonisolated private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        guard frameLength > 0 else { return }
        
        var sum: Float = 0.0
        
        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for i in 0..<frameLength {
                sum += abs(samples[i])
            }
        }
        
        let average = sum / Float(frameLength * channelCount)
        
        // Convert to normalized 0-1 range with strong amplification for visual effect
        // Apply logarithmic scaling for better dynamic range
        let amplified = Double(average) * 15.0
        let normalizedLevel = min(1.0, pow(amplified, 0.8))
        
        Task { @MainActor in
            self.updateAudioLevel(normalizedLevel)
        }
    }
    
    private func updateAudioLevel(_ level: Double) {
        // Use different smoothing for rising vs falling to make it more responsive
        // Fast attack (0.7) for rising levels, slower decay (0.3) for falling
        let isRising = level > audioLevel
        let smoothingFactor = isRising ? 0.7 : 0.4
        audioLevel = audioLevel * (1 - smoothingFactor) + level * smoothingFactor
        
        // Handle silence detection
        if audioLevel > silenceThreshold {
            isBreathing = false
            resetSilenceTimer()
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.isBreathing = true
            }
        }
    }
    
    // MARK: - Breathing Animation
    
    private func startBreathingAnimation() {
        breathingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isBreathing else { return }
                
                // Sinusoidal breathing effect
                self.breathingPhase += 0.05
                if self.breathingPhase > .pi * 2 {
                    self.breathingPhase = 0
                }
                
                // Generate subtle breathing level (0.02 to 0.08)
                let breathLevel = 0.05 + sin(self.breathingPhase) * 0.03
                self.audioLevel = breathLevel
            }
        }
        
        // Start breathing after initial silence delay
        DispatchQueue.main.asyncAfter(deadline: .now() + silenceDelay) { [weak self] in
            if self?.audioLevel ?? 0 < self?.silenceThreshold ?? 0.02 {
                self?.isBreathing = true
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        silenceTimer?.invalidate()
        breathingTimer?.invalidate()
    }
}
