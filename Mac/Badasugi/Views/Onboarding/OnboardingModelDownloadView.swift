import SwiftUI

struct OnboardingModelDownloadView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var whisperState: WhisperState
    @State private var scale: CGFloat = 0.8
    @State private var opacity: CGFloat = 0
    @State private var isDownloading = false
    @State private var isModelSet = false
    @State private var downloadError: String?
    
    // Large v3 Turbo 로컬 모델을 명시적으로 고정
    private var turboModel: LocalModel {
        // PredefinedModels에서 명시적으로 LocalModel 타입의 ggml-large-v3-turbo를 찾음
        guard let model = PredefinedModels.models.first(where: { 
            $0.name == "ggml-large-v3-turbo" && $0.provider == .local
        }) as? LocalModel else {
            // Fallback: 직접 생성 (안정성을 위해)
            return LocalModel(
                name: "ggml-large-v3-turbo",
                displayName: "Large v3 Turbo (로컬)",
                size: "1.5 GB",
                supportedLanguages: PredefinedModels.getLanguageDictionary(isMultilingual: true, provider: .local),
                description: "오프라인에서도 사용 가능한 고정확도 로컬 모델. 인터넷 연결 없이 한국어 음성 인식을 제공합니다.",
                speed: 0.75,
                accuracy: 0.97,
                ramUsage: 1.8
            )
        }
        return model
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                // Reusable background
                OnboardingBackgroundView()
                
                VStack(spacing: 40) {
                    // Model icon and title
                    VStack(spacing: 30) {
                        // Model icon
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            if isModelSet {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.accentColor)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Image(systemName: "brain")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .scaleEffect(scale)
                        .opacity(opacity)
                        
                        // Title and description
                        VStack(spacing: 12) {
                            Text("AI 모델 다운로드")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("최적화된 모델을 다운로드하여 시작하겠습니다.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .scaleEffect(scale)
                        .opacity(opacity)
                    }
                    
                    // Model card - Centered and compact
                    VStack(alignment: .leading, spacing: 16) {
                        // Model name and details
                        VStack(alignment: .center, spacing: 8) {
                            Text(turboModel.displayName)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(turboModel.size) • \(turboModel.language)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        // Performance indicators in a more compact layout
                        HStack(spacing: 20) {
                            performanceIndicator(label: "속도", value: turboModel.speed)
                            performanceIndicator(label: "정확도", value: turboModel.accuracy)
                            ramUsageLabel(gb: turboModel.ramUsage)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Download progress
                        if isDownloading {
                            DownloadProgressView(
                                modelName: turboModel.name,
                                downloadProgress: whisperState.downloadProgress
                            )
                            .transition(.opacity)
                        }
                        
                        // Error message
                        if let error = downloadError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                                .transition(.opacity)
                        }
                    }
                    .padding(24)
                    .frame(width: min(geometry.size.width * 0.6, 400))
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: handleAction) {
                            Text(getButtonTitle())
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 200, height: 50)
                                .background(Color.accentColor)
                                .cornerRadius(25)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(isDownloading)
                        
                        if !isModelSet {
                            SkipButton(text: "나중에") {
                                hasCompletedOnboarding = true
                            }
                        }
                    }
                    .opacity(opacity)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(width: min(geometry.size.width * 0.8, 600))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .onAppear {
            animateIn()
            checkModelStatus()
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1
            opacity = 1
        }
    }
    
    private func checkModelStatus() {
        // 명시적으로 로컬 모델만 확인
        if whisperState.availableModels.contains(where: { 
            $0.name == turboModel.name 
        }) {
            // 현재 설정된 모델이 우리가 원하는 로컬 모델인지 확인
            if let currentModel = whisperState.currentTranscriptionModel,
               currentModel.name == turboModel.name,
               currentModel.provider == .local {
                isModelSet = true
            }
        }
    }
    
    private func handleAction() {
        // 에러 메시지 초기화
        downloadError = nil
        
        if isModelSet {
            hasCompletedOnboarding = true
        } else if whisperState.availableModels.contains(where: { $0.name == turboModel.name }) {
            // 이미 다운로드된 경우: 기본값으로 설정
            if let modelToSet = whisperState.allAvailableModels.first(where: { 
                $0.name == turboModel.name && $0.provider == .local
            }) {
                Task {
                    await whisperState.setDefaultTranscriptionModel(modelToSet)
                    await MainActor.run {
                        withAnimation {
                            isModelSet = true
                        }
                    }
                }
            } else {
                downloadError = "모델을 찾을 수 없습니다. 다시 시도해주세요."
            }
        } else {
            // 다운로드 필요: 명시적으로 로컬 모델 다운로드
            withAnimation {
                isDownloading = true
                downloadError = nil
            }
            
            Task {
                // 명시적으로 LocalModel 타입 확인
                guard turboModel.provider == .local else {
                    await MainActor.run {
                        downloadError = "로컬 모델만 다운로드할 수 있습니다."
                        isDownloading = false
                    }
                    return
                }
                
                // 로컬 모델 다운로드 실행
                await whisperState.downloadModel(turboModel)
                
                // 다운로드 완료 후 모델 설정
                await MainActor.run {
                    // 다운로드된 모델 확인
                    if whisperState.availableModels.contains(where: { $0.name == turboModel.name }) {
                        if let modelToSet = whisperState.allAvailableModels.first(where: { 
                            $0.name == turboModel.name && $0.provider == .local
                        }) {
                            Task {
                                await whisperState.setDefaultTranscriptionModel(modelToSet)
                                await MainActor.run {
                                    withAnimation {
                                        isModelSet = true
                                        isDownloading = false
                                        downloadError = nil
                                    }
                                }
                            }
                        } else {
                            downloadError = "모델 설정에 실패했습니다. 다시 시도해주세요."
                            isDownloading = false
                        }
                    } else {
                        downloadError = "다운로드에 실패했습니다. 인터넷 연결을 확인하고 다시 시도해주세요."
                        isDownloading = false
                    }
                }
            }
        }
    }
    
    private func getButtonTitle() -> String {
        if isModelSet {
            return "계속하기"
        } else if isDownloading {
            return "다운로드 중..."
        } else if whisperState.availableModels.contains(where: { $0.name == turboModel.name }) {
            return "기본값으로 설정"
        } else {
            return "모델 다운로드"
        }
    }
    
    private func performanceIndicator(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(Double(index) / 5.0 <= value ? Color.accentColor : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
    
    private func ramUsageLabel(gb: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("메모리")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(String(format: "%.1f GB", gb))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

