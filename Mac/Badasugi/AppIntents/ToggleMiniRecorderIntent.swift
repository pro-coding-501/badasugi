import AppIntents
import Foundation
import AppKit

struct ToggleMiniRecorderIntent: AppIntent {
    static var title: LocalizedStringResource = "받아쓰기 녹음기 토글"
    static var description = IntentDescription("받아쓰기 미니 녹음기를 시작하거나 중지합니다.")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        NotificationCenter.default.post(name: .toggleMiniRecorder, object: nil)
        
        let dialog = IntentDialog(stringLiteral: "받아쓰기 녹음기 토글됨")
        return .result(dialog: dialog)
    }
}

enum IntentError: Error, LocalizedError {
    case appNotAvailable
    case serviceNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .appNotAvailable:
            return "받아쓰기 앱을 사용할 수 없습니다"
        case .serviceNotAvailable:
            return "받아쓰기 녹음 서비스를 사용할 수 없습니다"
        }
    }
}
