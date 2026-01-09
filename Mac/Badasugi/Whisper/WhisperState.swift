import Foundation
import SwiftUI
import AVFoundation
import SwiftData
import AppKit
import KeyboardShortcuts
import os

// MARK: - Recording State Machine
enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case enhancing
    case busy
}

enum RecorderType: String, CaseIterable, Identifiable {
    case notch = "notch"
    case mini = "mini"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .notch: return "노치 녹음기"
        case .mini: return "미니 녹음기"
        }
    }
    
    var description: String {
        switch self {
        case .notch: return "화면 상단 노치 영역에 표시"
        case .mini: return "화면 중앙에 떠있는 창으로 표시"
        }
    }
    
    var icon: String {
        switch self {
        case .notch: return "rectangle.topthird.inset.filled"
        case .mini: return "rectangle.fill"
        }
    }
}

@MainActor
class WhisperState: NSObject, ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var isModelLoaded = false
    @Published var loadedLocalModel: WhisperModel?
    @Published var currentTranscriptionModel: (any TranscriptionModel)?
    @Published var isModelLoading = false
    @Published var availableModels: [WhisperModel] = []
    @Published var allAvailableModels: [any TranscriptionModel] = PredefinedModels.models
    @Published var clipboardMessage = ""
    @Published var miniRecorderError: String?
    @Published var shouldCancelRecording = false
    
    // Onboarding mode flag to prevent auto-pasting during tutorial
    @Published var isOnboardingMode = false
    
    // Prevent duplicate toggleMiniRecorder calls
    var isToggleMiniRecorderProcessing = false
    var lastToggleMiniRecorderTime: Date?
    let toggleMiniRecorderCooldown: TimeInterval = 0.3 // 300ms cooldown


    // Always use mini recorder style
    let recorderType: RecorderType = .mini
    
    @Published var isMiniRecorderVisible = false {
        didSet {
            if isMiniRecorderVisible {
                showRecorderPanel()
            } else {
                hideRecorderPanel()
            }
        }
    }
    
    var whisperContext: WhisperContext?
    let recorder = Recorder()
    var recordedFile: URL? = nil
    let whisperPrompt = WhisperPrompt()
    
    // Prompt detection service for trigger word handling
    private let promptDetectionService = PromptDetectionService()
    
    let modelContext: ModelContext
    
    internal var serviceRegistry: TranscriptionServiceRegistry!
    
    private var modelUrl: URL? {
        let possibleURLs = [
            Bundle.main.url(forResource: "ggml-base.en", withExtension: "bin", subdirectory: "Models"),
            Bundle.main.url(forResource: "ggml-base.en", withExtension: "bin"),
            Bundle.main.bundleURL.appendingPathComponent("Models/ggml-base.en.bin")
        ]
        
        for url in possibleURLs {
            if let url = url, FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }
    
    private enum LoadError: Error {
        case couldNotLocateModel
    }
    
    let modelsDirectory: URL
    let recordingsDirectory: URL
    let enhancementService: AIEnhancementService?
    var licenseViewModel: LicenseViewModel
    let logger = Logger(subsystem: "com.badasugi.app", category: "WhisperState")
    var miniWindowManager: MiniWindowManager?
    
    // For model progress tracking
    @Published var downloadProgress: [String: Double] = [:]
    @Published var parakeetDownloadStates: [String: Bool] = [:]
    
    init(modelContext: ModelContext, enhancementService: AIEnhancementService? = nil) {
        self.modelContext = modelContext
        let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Badasugi")
        
        self.modelsDirectory = appSupportDirectory.appendingPathComponent("WhisperModels")
        self.recordingsDirectory = appSupportDirectory.appendingPathComponent("Recordings")
        
        self.enhancementService = enhancementService
        self.licenseViewModel = LicenseViewModel()
        
        super.init()
        
        // Configure the session manager
        if let enhancementService = enhancementService {
            PowerModeSessionManager.shared.configure(whisperState: self, enhancementService: enhancementService)
        }

        // Initialize the transcription service registry
        self.serviceRegistry = TranscriptionServiceRegistry(whisperState: self, modelsDirectory: self.modelsDirectory)
        
        setupNotifications()
        createModelsDirectoryIfNeeded()
        createRecordingsDirectoryIfNeeded()
        loadAvailableModels()
        loadCurrentTranscriptionModel()
        refreshAllAvailableModels()
    }
    
    private func createRecordingsDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.error("Error creating recordings directory: \(error.localizedDescription)")
        }
    }
    
    // Track last processed file to prevent duplicates
    private var lastProcessedFileURL: String?
    private var lastProcessedTime: Date?
    
    func toggleRecord(powerModeId: UUID? = nil) async {
        // GUARD 1: Prevent duplicate calls while already processing
        if recordingState == .transcribing || recordingState == .enhancing || recordingState == .busy {
            logger.warning("⚠️ Ignoring toggleRecord call - already processing (state: \(String(describing: self.recordingState)))")
            return
        }
        
        if recordingState == .recording {
            // GUARD 2: Immediately set state to busy to prevent race conditions
            await MainActor.run {
                recordingState = .busy
            }
            
            await recorder.stopRecording()
            
            if let recordedFile {
                // GUARD 3: Check if this file was already processed recently (within 2 seconds)
                let fileURLString = recordedFile.absoluteString
                if let lastURL = lastProcessedFileURL, 
                   let lastTime = lastProcessedTime,
                   lastURL == fileURLString,
                   Date().timeIntervalSince(lastTime) < 2.0 {
                    logger.warning("⚠️ Duplicate file processing detected, ignoring: \(fileURLString)")
                    await MainActor.run {
                        recordingState = .idle
                    }
                    return
                }
                
                // Mark this file as being processed
                lastProcessedFileURL = fileURLString
                lastProcessedTime = Date()
                
                if !shouldCancelRecording {
                    let audioAsset = AVURLAsset(url: recordedFile)
                    let duration = (try? CMTimeGetSeconds(await audioAsset.load(.duration))) ?? 0.0

                    // GUARD 4: Check if a transcription with this audio URL already exists (DB level dedup)
                    let audioURLString = recordedFile.absoluteString
                    var existingDescriptor = FetchDescriptor<Transcription>(
                        predicate: #Predicate { $0.audioFileURL == audioURLString }
                    )
                    existingDescriptor.fetchLimit = 1
                    
                    if let existing = try? modelContext.fetch(existingDescriptor).first {
                        logger.warning("⚠️ Transcription already exists for this audio file, skipping duplicate insert: \(audioURLString)")
                        // Continue with existing transcription instead of creating new one
                        await transcribeAudio(on: existing)
                        return
                    }
                    
                    let transcription = Transcription(
                        text: "",
                        duration: duration,
                        audioFileURL: recordedFile.absoluteString,
                        transcriptionStatus: .pending
                    )
                    modelContext.insert(transcription)
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .transcriptionCreated, object: transcription)

                    await transcribeAudio(on: transcription)
                } else {
                    await MainActor.run {
                        recordingState = .idle
                    }
                    await cleanupModelResources()
                }
            } else {
                logger.error("❌ No recorded file found after stopping recording")
                await MainActor.run {
                    recordingState = .idle
                }
            }
        } else if recordingState == .idle {
            guard currentTranscriptionModel != nil else {
                await MainActor.run {
                    NotificationManager.shared.showNotification(
                        title: "No AI Model Selected",
                        type: .error
                    )
                }
                return
            }
            shouldCancelRecording = false
            requestRecordPermission { [self] granted in
                if granted {
                    Task {
                        do {
                            // --- Prepare permanent file URL ---
                            let fileName = "\(UUID().uuidString).wav"
                            let permanentURL = self.recordingsDirectory.appendingPathComponent(fileName)
                            self.recordedFile = permanentURL

                            try await self.recorder.startRecording(toOutputFile: permanentURL)

                            await MainActor.run {
                                self.recordingState = .recording
                            }

                            if let powerModeId = powerModeId {
                                await ActiveWindowService.shared.applyConfiguration(powerModeId: powerModeId)
                            } else {
                                let hasActiveSession = await PowerModeSessionManager.shared.hasActiveSession
                                if !hasActiveSession {
                                    await ActiveWindowService.shared.applyConfiguration()
                                }
                            }

                            // Load model and capture context in background without blocking
                            Task.detached { [weak self] in
                                guard let self = self else { return }

                                // Only load model if it's a local model and not already loaded
                                if let model = await self.currentTranscriptionModel, model.provider == .local {
                                    if let localWhisperModel = await self.availableModels.first(where: { $0.name == model.name }),
                                       await self.whisperContext == nil {
                                        do {
                                            try await self.loadModel(localWhisperModel)
                                        } catch {
                                            await self.logger.error("❌ Model loading failed: \(error.localizedDescription)")
                                        }
                                    }
                                } else if let parakeetModel = await self.currentTranscriptionModel as? ParakeetModel {
                                    try? await self.serviceRegistry.parakeetTranscriptionService.loadModel(for: parakeetModel)
                                }

                                if let enhancementService = await self.enhancementService {
                                    await MainActor.run {
                                        enhancementService.captureClipboardContext()
                                    }
                                    await enhancementService.captureScreenContext()
                                }
                            }

                        } catch {
                            self.logger.error("❌ Failed to start recording: \(error.localizedDescription)")
                            await NotificationManager.shared.showNotification(title: "Recording failed to start", type: .error)
                            await self.dismissMiniRecorder()
                            // Do not remove the file on a failed start, to preserve all recordings.
                            self.recordedFile = nil
                        }
                    }
                } else {
                    logger.error("❌ Recording permission denied.")
                }
            }
        }
    }
    
    private func requestRecordPermission(response: @escaping (Bool) -> Void) {
        response(true)
    }
    
    private func transcribeAudio(on transcription: Transcription) async {
        guard let urlString = transcription.audioFileURL, let url = URL(string: urlString) else {
            logger.error("❌ Invalid audio file URL in transcription object.")
            await MainActor.run {
                recordingState = .idle
            }
            transcription.text = "Transcription Failed: Invalid audio file URL"
            transcription.transcriptionStatus = TranscriptionStatus.failed.rawValue
            try? modelContext.save()
            return
        }

        if shouldCancelRecording {
            await MainActor.run {
                recordingState = .idle
            }
            await cleanupModelResources()
            return
        }

        await MainActor.run {
            recordingState = .transcribing
        }

        // Play stop sound when transcription starts with a small delay
        Task {
            let isSystemMuteEnabled = UserDefaults.standard.bool(forKey: "isSystemMuteEnabled")
            if isSystemMuteEnabled {
                try? await Task.sleep(nanoseconds: 200_000_000) // 200 milliseconds delay
            }
            await MainActor.run {
                SoundManager.shared.playStopSound()
            }
        }

        defer {
            if shouldCancelRecording {
                Task {
                    await cleanupModelResources()
                }
            }
        }

        logger.notice("🔄 Starting transcription...")
        
        var finalPastedText: String?
        var promptDetectionResult: PromptDetectionService.PromptDetectionResult?

        do {
            guard let model = currentTranscriptionModel else {
                throw WhisperStateError.transcriptionFailed
            }

            let transcriptionStart = Date()
            var text = try await serviceRegistry.transcribe(audioURL: url, model: model)
            logger.notice("📝 Raw transcript: \(text, privacy: .public)")
            text = TranscriptionOutputFilter.filter(text)
            logger.notice("📝 Output filter result: \(text, privacy: .public)")
            let transcriptionDuration = Date().timeIntervalSince(transcriptionStart)

            let powerModeManager = PowerModeManager.shared
            let activePowerModeConfig = powerModeManager.currentActiveConfiguration
            let powerModeName = (activePowerModeConfig?.isEnabled == true) ? activePowerModeConfig?.name : nil
            let powerModeEmoji = (activePowerModeConfig?.isEnabled == true) ? activePowerModeConfig?.emoji : nil

            if await checkCancellationAndCleanup() { return }

            text = text.trimmingCharacters(in: .whitespacesAndNewlines)

            if UserDefaults.standard.object(forKey: "IsAutoPunctuationEnabled") as? Bool ?? false {
                let punctuated = AutoPunctuationService.apply(to: text)
                if punctuated != text {
                    text = punctuated
                    logger.notice("📝 Auto punctuated transcript: \(text, privacy: .public)")
                }
            }

            if UserDefaults.standard.object(forKey: "IsTextFormattingEnabled") as? Bool ?? true {
                text = WhisperTextFormatter.format(text)
                logger.notice("📝 Formatted transcript: \(text, privacy: .public)")
            }

            text = WordReplacementService.shared.applyReplacements(to: text, using: modelContext)
            logger.notice("📝 WordReplacement: \(text, privacy: .public)")

            let audioAsset = AVURLAsset(url: url)
            let actualDuration = (try? CMTimeGetSeconds(await audioAsset.load(.duration))) ?? 0.0
            
            transcription.text = text
            transcription.duration = actualDuration
            transcription.transcriptionModelName = model.displayName
            transcription.transcriptionDuration = transcriptionDuration
            transcription.powerModeName = powerModeName
            transcription.powerModeEmoji = powerModeEmoji
            finalPastedText = text

            // Deduplicate: if the most recent transcription has identical text within 2 seconds, skip this one
            do {
                var descriptor = FetchDescriptor<Transcription>(
                    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                )
                descriptor.fetchLimit = 1
                let recent = try modelContext.fetch(descriptor).first { $0.id != transcription.id }
                if let recent = recent {
                    let timeDiff = abs(recent.timestamp.timeIntervalSince(transcription.timestamp))
                    if recent.text == text && timeDiff < 2 {
                        logger.warning("⚠️ Duplicate transcription detected (same text within 2s). Skipping save/paste.")
                        modelContext.delete(transcription)
                        try? modelContext.save()
                        await MainActor.run {
                            recordingState = .idle
                        }
                        return
                    }
                }
            } catch {
                logger.error("Duplicate check failed: \(error.localizedDescription)")
            }
            
            if let enhancementService = enhancementService, enhancementService.isConfigured {
                let detectionResult = await promptDetectionService.analyzeText(text, with: enhancementService)
                promptDetectionResult = detectionResult
                await promptDetectionService.applyDetectionResult(detectionResult, to: enhancementService)
            }

            if let enhancementService = enhancementService,
               enhancementService.isEnhancementEnabled,
               enhancementService.isConfigured {
                if await checkCancellationAndCleanup() { return }

                await MainActor.run { self.recordingState = .enhancing }
                let textForAI = promptDetectionResult?.processedText ?? text
                
                do {
                    let (enhancedText, enhancementDuration, promptName) = try await enhancementService.enhance(textForAI)
                    logger.notice("📝 AI enhancement: \(enhancedText, privacy: .public)")
                    transcription.enhancedText = enhancedText
                    transcription.aiEnhancementModelName = enhancementService.getAIService()?.currentModel
                    transcription.promptName = promptName
                    transcription.enhancementDuration = enhancementDuration
                    transcription.aiRequestSystemMessage = enhancementService.lastSystemMessageSent
                    transcription.aiRequestUserMessage = enhancementService.lastUserMessageSent
                    finalPastedText = enhancedText
                } catch {
                    transcription.enhancedText = "Enhancement failed: \(error)"
                  
                    if await checkCancellationAndCleanup() { return }
                }
            }

            transcription.transcriptionStatus = TranscriptionStatus.completed.rawValue

        } catch {
            let errorDescription = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            let recoverySuggestion = (error as? LocalizedError)?.recoverySuggestion ?? ""
            let fullErrorText = recoverySuggestion.isEmpty ? errorDescription : "\(errorDescription) \(recoverySuggestion)"

            transcription.text = "Transcription Failed: \(fullErrorText)"
            transcription.transcriptionStatus = TranscriptionStatus.failed.rawValue
        }

        // --- Finalize and save ---
        try? modelContext.save()
        
        if transcription.transcriptionStatus == TranscriptionStatus.completed.rawValue {
            NotificationCenter.default.post(name: .transcriptionCompleted, object: transcription)
        }

        if await checkCancellationAndCleanup() { return }

        // Skip auto-pasting during onboarding to prevent duplicate text input
        if var textToPaste = finalPastedText, transcription.transcriptionStatus == TranscriptionStatus.completed.rawValue, !isOnboardingMode {
            if case .trialExpired = licenseViewModel.licenseState {
                textToPaste = """
                    체험 기간이 만료되었습니다. 받아쓰기 웹사이트를 방문하세요: www.badasugi.com
                    \n\(textToPaste)
                    """
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let shouldAppendTrailingSpace = UserDefaults.standard.object(forKey: "AppendTrailingSpace") as? Bool ?? true
                let pasteText = shouldAppendTrailingSpace
                    ? (textToPaste.hasSuffix(" ") ? textToPaste : textToPaste + " ")
                    : textToPaste
                let pasteSuccess = CursorPaster.pasteAtCursor(pasteText)
                
                if !pasteSuccess {
                    NotificationManager.shared.showNotification(
                        title: "텍스트가 클립보드에 복사되었습니다. 수동으로 붙여넣기(Cmd+V)를 사용하세요.",
                        type: .warning,
                        duration: 5.0
                    )
                }

                let powerMode = PowerModeManager.shared
                if let activeConfig = powerMode.currentActiveConfiguration, activeConfig.isAutoSendEnabled && pasteSuccess {
                    // Slight delay to ensure the paste operation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        CursorPaster.pressEnter()
                    }
                }
            }
        }

        if let result = promptDetectionResult,
           let enhancementService = enhancementService,
           result.shouldEnableAI {
            await promptDetectionService.restoreOriginalSettings(result, to: enhancementService)
        }

        await self.dismissMiniRecorder()

        shouldCancelRecording = false
    }

    func getEnhancementService() -> AIEnhancementService? {
        return enhancementService
    }
    
    private func checkCancellationAndCleanup() async -> Bool {
        if shouldCancelRecording {
            await cleanupModelResources()
            return true
        }
        return false
    }

    private func cleanupAndDismiss() async {
        await dismissMiniRecorder()
    }
}
