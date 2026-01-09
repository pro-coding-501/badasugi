import Foundation
import SwiftData
import os

enum CloudTranscriptionError: Error, LocalizedError {
    case unsupportedProvider
    case missingAPIKey
    case missingAPIKeyWithService(serviceName: String)
    case invalidAPIKey
    case audioFileNotFound
    case apiRequestFailed(statusCode: Int, message: String)
    case networkError(Error)
    case noTranscriptionReturned
    case dataEncodingError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedProvider:
            return "이 서비스에서 지원하지 않는 모델 제공업체입니다."
        case .missingAPIKey:
            return "API 키가 설정되지 않았습니다. 설정 > 음성 인식 > 모델 관리에서 해당 서비스의 API 키를 입력하세요."
        case .missingAPIKeyWithService(let serviceName):
            return "\(serviceName) API 키가 설정되지 않았습니다. 설정 > 음성 인식 > 모델 관리에서 \(serviceName)의 API 키를 입력하세요."
        case .invalidAPIKey:
            return "입력하신 API 키가 유효하지 않습니다."
        case .audioFileNotFound:
            return "전사할 오디오 파일을 찾을 수 없습니다."
        case .apiRequestFailed(let statusCode, let message):
            return "API 요청이 실패했습니다 (상태 코드: \(statusCode)): \(message)"
        case .networkError(let error):
            return "네트워크 오류가 발생했습니다: \(error.localizedDescription)"
        case .noTranscriptionReturned:
            return "API가 빈 응답 또는 잘못된 응답을 반환했습니다."
        case .dataEncodingError:
            return "요청 본문 인코딩에 실패했습니다."
        }
    }
}

class CloudTranscriptionService: TranscriptionService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private lazy var groqService = GroqTranscriptionService()
    private lazy var elevenLabsService = ElevenLabsTranscriptionService()
    private lazy var deepgramService = DeepgramTranscriptionService()
    private lazy var mistralService = MistralTranscriptionService()
    private lazy var geminiService = GeminiTranscriptionService()
    private lazy var openAICompatibleService = OpenAICompatibleTranscriptionService()
    private lazy var sonioxService = SonioxTranscriptionService(modelContext: modelContext)
    
    func transcribe(audioURL: URL, model: any TranscriptionModel) async throws -> String {
        var text: String
        
        do {
            switch model.provider {
            case .groq:
                text = try await groqService.transcribe(audioURL: audioURL, model: model)
            case .elevenLabs:
                text = try await elevenLabsService.transcribe(audioURL: audioURL, model: model)
            case .deepgram:
                text = try await deepgramService.transcribe(audioURL: audioURL, model: model)
            case .mistral:
                text = try await mistralService.transcribe(audioURL: audioURL, model: model)
            case .gemini:
                text = try await geminiService.transcribe(audioURL: audioURL, model: model)
            case .soniox:
                text = try await sonioxService.transcribe(audioURL: audioURL, model: model)
            case .custom:
                guard let customModel = model as? CustomCloudModel else {
                    throw CloudTranscriptionError.unsupportedProvider
                }
                text = try await openAICompatibleService.transcribe(audioURL: audioURL, model: customModel)
            default:
                throw CloudTranscriptionError.unsupportedProvider
            }
        } catch let error as CloudTranscriptionError {
            if case .missingAPIKey = error {
                let serviceName = getServiceName(for: model.provider)
                throw CloudTranscriptionError.missingAPIKeyWithService(serviceName: serviceName)
            }
            throw error
        }
        
        return text
    }
    
    private func getServiceName(for provider: ModelProvider) -> String {
        switch provider {
        case .groq: return "Groq"
        case .elevenLabs: return "ElevenLabs"
        case .deepgram: return "Deepgram"
        case .mistral: return "Mistral"
        case .gemini: return "Gemini"
        case .soniox: return "Soniox"
        case .custom: return "사용자 지정"
        default: return "알 수 없음"
        }
    }

    

} 