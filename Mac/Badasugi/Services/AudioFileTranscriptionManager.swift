import Foundation
import SwiftUI
import AVFoundation
import SwiftData
import os

@MainActor
class AudioTranscriptionManager: ObservableObject {
    static let shared = AudioTranscriptionManager()
    
    @Published var isProcessing = false
    @Published var processingPhase: ProcessingPhase = .idle
    @Published var currentTranscription: Transcription?
    @Published var errorMessage: String?
    
    private var currentTask: Task<Void, Error>?
    private let audioProcessor = AudioProcessor()
    private let logger = Logger(subsystem: "com.badasugi.app", category: "AudioTranscriptionManager")
    
    enum ProcessingPhase {
        case idle
        case loading
        case processingAudio
        case transcribing
        case enhancing
        case completed
        
        var message: String {
            switch self {
            case .idle:
                return ""
            case .loading:
                return "기록 모델 로딩 중..."
            case .processingAudio:
                return "기록을 위해 오디오 파일 처리 중..."
            case .transcribing:
                return "오디오 기록 중..."
            case .enhancing:
                return "AI로 기록 결과 향상 중..."
            case .completed:
                return "기록 완료!"
            }
        }
    }
    
    private init() {}
    
    func startProcessing(url: URL, modelContext: ModelContext, whisperState: WhisperState) {
        // Cancel any existing processing
        cancelProcessing()
        
        isProcessing = true
        processingPhase = .loading
        errorMessage = nil
        
        currentTask = Task {
            do {
                guard let currentModel = whisperState.currentTranscriptionModel else {
                    throw TranscriptionError.noModelSelected
                }

                let serviceRegistry = TranscriptionServiceRegistry(whisperState: whisperState, modelsDirectory: whisperState.modelsDirectory)
                defer {
                    serviceRegistry.cleanup()
                }

                processingPhase = .processingAudio
                let samples = try await audioProcessor.processAudioToSamples(url)

                let audioAsset = AVURLAsset(url: url)
                let duration = CMTimeGetSeconds(try await audioAsset.load(.duration))

                let recordingsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("Badasugi")
                    .appendingPathComponent("Recordings")

                let fileName = "transcribed_\(UUID().uuidString).wav"
                let permanentURL = recordingsDirectory.appendingPathComponent(fileName)

                try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
                try audioProcessor.saveSamplesAsWav(samples: samples, to: permanentURL)

                processingPhase = .transcribing
                let transcriptionStart = Date()
                var text = try await serviceRegistry.transcribe(audioURL: permanentURL, model: currentModel)
                let transcriptionDuration = Date().timeIntervalSince(transcriptionStart)
                text = TranscriptionOutputFilter.filter(text)
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)

                if UserDefaults.standard.object(forKey: "IsAutoPunctuationEnabled") as? Bool ?? false {
                    text = AutoPunctuationService.apply(to: text)
                }

                let powerModeManager = PowerModeManager.shared
                let activePowerModeConfig = powerModeManager.currentActiveConfiguration
                let powerModeName = (activePowerModeConfig?.isEnabled == true) ? activePowerModeConfig?.name : nil
                let powerModeEmoji = (activePowerModeConfig?.isEnabled == true) ? activePowerModeConfig?.emoji : nil

                if UserDefaults.standard.object(forKey: "IsTextFormattingEnabled") as? Bool ?? true {
                    text = WhisperTextFormatter.format(text)
                }

                text = WordReplacementService.shared.applyReplacements(to: text, using: modelContext)
                
                // Handle enhancement if enabled
                if let enhancementService = whisperState.enhancementService,
                   enhancementService.isEnhancementEnabled,
                   enhancementService.isConfigured {
                    processingPhase = .enhancing
                    do {
                        // inside the enhancement success path where transcription is created
                        let (enhancedText, enhancementDuration, promptName) = try await enhancementService.enhance(text)
                        let transcription = Transcription(
                            text: text,
                            duration: duration,
                            enhancedText: enhancedText,
                            audioFileURL: permanentURL.absoluteString,
                            transcriptionModelName: currentModel.displayName,
                            aiEnhancementModelName: enhancementService.getAIService()?.currentModel,
                            promptName: promptName,
                            transcriptionDuration: transcriptionDuration,
                            enhancementDuration: enhancementDuration,
                            aiRequestSystemMessage: enhancementService.lastSystemMessageSent,
                            aiRequestUserMessage: enhancementService.lastUserMessageSent,
                            powerModeName: powerModeName,
                            powerModeEmoji: powerModeEmoji
                        )
                        modelContext.insert(transcription)
                        try modelContext.save()
                        NotificationCenter.default.post(name: .transcriptionCreated, object: transcription)
                        currentTranscription = transcription
                    } catch {
                        logger.error("Enhancement failed: \(error.localizedDescription)")
                        let transcription = Transcription(
                            text: text,
                            duration: duration,
                            audioFileURL: permanentURL.absoluteString,
                            transcriptionModelName: currentModel.displayName,
                            promptName: nil,
                            transcriptionDuration: transcriptionDuration,
                            powerModeName: powerModeName,
                            powerModeEmoji: powerModeEmoji
                        )
                        modelContext.insert(transcription)
                        try modelContext.save()
                        NotificationCenter.default.post(name: .transcriptionCreated, object: transcription)
                        currentTranscription = transcription
                    }
                } else {
                    let transcription = Transcription(
                        text: text,
                        duration: duration,
                        audioFileURL: permanentURL.absoluteString,
                        transcriptionModelName: currentModel.displayName,
                        promptName: nil,
                        transcriptionDuration: transcriptionDuration,
                        powerModeName: powerModeName,
                        powerModeEmoji: powerModeEmoji
                    )
                    modelContext.insert(transcription)
                    try modelContext.save()
                    NotificationCenter.default.post(name: .transcriptionCreated, object: transcription)
                    currentTranscription = transcription
                }
                
                processingPhase = .completed
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await finishProcessing()
                
            } catch {
                await handleError(error)
            }
        }
    }
    
    func cancelProcessing() {
        currentTask?.cancel()
    }
    
    private func finishProcessing() {
        isProcessing = false
        processingPhase = .idle
        currentTask = nil
    }
    
    private func handleError(_ error: Error) {
        logger.error("Transcription error: \(error.localizedDescription)")
        errorMessage = error.localizedDescription
        isProcessing = false
        processingPhase = .idle
        currentTask = nil
    }
}

enum TranscriptionError: Error, LocalizedError {
    case noModelSelected
    case transcriptionCancelled
    
    var errorDescription: String? {
        switch self {
        case .noModelSelected:
            return "기록 모델이 선택되지 않았습니다"
        case .transcriptionCancelled:
            return "기록이 취소되었습니다"
        }
    }
}
