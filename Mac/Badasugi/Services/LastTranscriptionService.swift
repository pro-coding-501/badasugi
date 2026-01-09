import Foundation
import SwiftData

class LastTranscriptionService: ObservableObject {
    
    static func getLastTranscription(from modelContext: ModelContext) -> Transcription? {
        var descriptor = FetchDescriptor<Transcription>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        do {
            let transcriptions = try modelContext.fetch(descriptor)
            return transcriptions.first
        } catch {
            print("Error fetching last transcription: \(error)")
            return nil
        }
    }
    
    static func copyLastTranscription(from modelContext: ModelContext) {
        guard let lastTranscription = getLastTranscription(from: modelContext) else {
            Task { @MainActor in
                NotificationManager.shared.showNotification(
                    title: "No transcription available",
                    type: .error
                )
            }
            return
        }
        
        // Prefer enhanced text; fallback to original text
        let textToCopy: String = {
            if let enhancedText = lastTranscription.enhancedText, !enhancedText.isEmpty {
                return enhancedText
            } else {
                return lastTranscription.text
            }
        }()
        
        let success = ClipboardManager.copyToClipboard(textToCopy)
        
        Task { @MainActor in
            if success {
                NotificationManager.shared.showNotification(
                    title: "Last transcription copied",
                    type: .success
                )
            } else {
                NotificationManager.shared.showNotification(
                    title: "Failed to copy transcription",
                    type: .error
                )
            }
        }
    }

    static func pasteLastTranscription(from modelContext: ModelContext) {
        guard let lastTranscription = getLastTranscription(from: modelContext) else {
            Task { @MainActor in
                NotificationManager.shared.showNotification(
                    title: "기록이 없습니다",
                    type: .error
                )
            }
            return
        }
        
        let shouldAppendTrailingSpace = UserDefaults.standard.object(forKey: "AppendTrailingSpace") as? Bool ?? true
        let baseText = lastTranscription.text
        let textToPaste = shouldAppendTrailingSpace
            ? (baseText.hasSuffix(" ") ? baseText : baseText + " ")
            : baseText

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let success = CursorPaster.pasteAtCursor(textToPaste)
            if !success {
                NotificationManager.shared.showNotification(
                    title: "텍스트가 클립보드에 복사되었습니다. 수동으로 붙여넣기(Cmd+V)를 사용하세요.",
                    type: .warning,
                    duration: 5.0
                )
            }
        }
    }
    
    static func pasteLastEnhancement(from modelContext: ModelContext) {
        guard let lastTranscription = getLastTranscription(from: modelContext) else {
            Task { @MainActor in
                NotificationManager.shared.showNotification(
                    title: "기록이 없습니다",
                    type: .error
                )
            }
            return
        }
        
        // Prefer enhanced text; if unavailable, fallback to original text (which may contain an error message)
        let shouldAppendTrailingSpace = UserDefaults.standard.object(forKey: "AppendTrailingSpace") as? Bool ?? true
        let textToPaste: String = {
            if let enhancedText = lastTranscription.enhancedText, !enhancedText.isEmpty {
                return enhancedText
            } else {
                return lastTranscription.text
            }
        }()
        let finalTextToPaste = shouldAppendTrailingSpace
            ? (textToPaste.hasSuffix(" ") ? textToPaste : textToPaste + " ")
            : textToPaste

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let success = CursorPaster.pasteAtCursor(finalTextToPaste)
            if !success {
                NotificationManager.shared.showNotification(
                    title: "텍스트가 클립보드에 복사되었습니다. 수동으로 붙여넣기(Cmd+V)를 사용하세요.",
                    type: .warning,
                    duration: 5.0
                )
            }
        }
    }
    
    static func retryLastTranscription(from modelContext: ModelContext, whisperState: WhisperState) {
        Task { @MainActor in
            guard let lastTranscription = getLastTranscription(from: modelContext),
                  let audioURLString = lastTranscription.audioFileURL,
                  let audioURL = URL(string: audioURLString),
                  FileManager.default.fileExists(atPath: audioURL.path) else {
                NotificationManager.shared.showNotification(
                    title: "Cannot retry: Audio file not found",
                    type: .error
                )
                return
            }
            
            guard let currentModel = whisperState.currentTranscriptionModel else {
                NotificationManager.shared.showNotification(
                    title: "No transcription model selected",
                    type: .error
                )
                return
            }
            
            let transcriptionService = AudioTranscriptionService(modelContext: modelContext, whisperState: whisperState)
            do {
                let newTranscription = try await transcriptionService.retranscribeAudio(from: audioURL, using: currentModel)
                
                let textToCopy = newTranscription.enhancedText?.isEmpty == false ? newTranscription.enhancedText! : newTranscription.text
                ClipboardManager.copyToClipboard(textToCopy)
                
                NotificationManager.shared.showNotification(
                    title: "Copied to clipboard",
                    type: .success
                )
            } catch {
                NotificationManager.shared.showNotification(
                    title: "Retry failed: \(error.localizedDescription)",
                    type: .error
                )
            }
        }
    }
}