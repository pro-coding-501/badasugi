import SwiftUI

struct ModelSettingsView: View {
    @ObservedObject var whisperPrompt: WhisperPrompt
    @AppStorage("SelectedLanguage") private var selectedLanguage: String = "ko"
    @AppStorage("IsTextFormattingEnabled") private var isTextFormattingEnabled = true
    @AppStorage("IsVADEnabled") private var isVADEnabled = true
    @AppStorage("AppendTrailingSpace") private var appendTrailingSpace = true
    @AppStorage("PrewarmModelOnWake") private var prewarmModelOnWake = true
    @AppStorage("IsAutoPunctuationEnabled") private var isAutoPunctuationEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Toggle(isOn: $appendTrailingSpace) {
                    Text("붙여넣기 후 공백 추가")
                }
                .toggleStyle(.switch)
                
                InfoTip(
                    title: "후행 공백",
                    message: "붙여넣은 텍스트 뒤에 자동으로 공백을 추가합니다. 공백으로 구분되는 언어에 유용합니다."
                )
            }

            HStack {
                Toggle(isOn: $isAutoPunctuationEnabled) {
                    Text("자동 구두점")
                }
                .toggleStyle(.switch)
                
                InfoTip(
                    title: "자동 구두점",
                    message: "음성 인식 시 문장 끝에 자동으로 마침표, 쉼표 등의 구두점을 추가합니다."
                )
            }

            HStack {
                Toggle(isOn: $isTextFormattingEnabled) {
                    Text("자동 텍스트 포맷팅")
                }
                .toggleStyle(.switch)
                
                InfoTip(
                    title: "자동 텍스트 포맷팅",
                    message: "큰 텍스트 블록을 단락으로 나누는 지능형 텍스트 포맷팅을 적용합니다."
                )
            }

            HStack {
                Toggle(isOn: $isVADEnabled) {
                    Text("음성 활동 감지 (VAD)")
                }
                .toggleStyle(.switch)

                InfoTip(
                    title: "음성 활동 감지",
                    message: "음성 구간을 감지하고 침묵을 필터링하여 로컬 모델의 정확도를 향상시킵니다."
                )
            }

            HStack {
                Toggle(isOn: $prewarmModelOnWake) {
                    Text("모델 사전 준비 (실험적)")
                }
                .toggleStyle(.switch)

                InfoTip(
                    title: "모델 사전 준비 (실험적)",
                    message: "로컬 모델로 전사하는 데 예상보다 시간이 오래 걸리는 경우 이 옵션을 켜세요. 앱 실행 및 깨우기 시 조용한 백그라운드 전사를 실행하여 최적화를 트리거합니다."
                )
            }

        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .onAppear {
            // 언어를 항상 한국어로 고정
            selectedLanguage = "ko"
        }
        // Reset the editor when language changes
        .onChange(of: selectedLanguage) { oldValue, newValue in
            // 언어를 항상 한국어로 유지
            if newValue != "ko" {
                selectedLanguage = "ko"
            }
        }
    }
} 
