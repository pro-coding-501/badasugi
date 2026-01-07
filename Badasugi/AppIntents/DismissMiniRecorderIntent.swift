import AppIntents
import Foundation
import AppKit

struct DismissMiniRecorderIntent: AppIntent {
    static var title: LocalizedStringResource = "받아쓰기 녹음기 닫기"
    static var description = IntentDescription("받아쓰기 미니 녹음기를 닫고 활성 녹음을 취소합니다.")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        NotificationCenter.default.post(name: .dismissMiniRecorder, object: nil)
        
        let dialog = IntentDialog(stringLiteral: "받아쓰기 녹음기 닫힘")
        return .result(dialog: dialog)
    }
}
