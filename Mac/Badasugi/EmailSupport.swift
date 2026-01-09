import Foundation
import SwiftUI
import AppKit

struct EmailSupport {
    static func generateSupportEmailURL() -> URL? {
        let to = "badasugi.app@gmail.com"
        let subject = "[받아쓰기] 지원 요청"
        
        let body = """
안녕하세요. 받아쓰기 지원 요청드립니다.

- 라이선스 키:
- 기기 이름:
- macOS 버전:
- 문제 설명:


"""
        
        // URL 인코딩 처리 (한글 및 특수문자 포함)
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: "mailto:\(to)?subject=\(encodedSubject)&body=\(encodedBody)")
    }
    
    static func openSupportEmail() {
        if let emailURL = generateSupportEmailURL() {
            NSWorkspace.shared.open(emailURL)
        }
    }
}