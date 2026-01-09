import SwiftUI
import AppKit

// MARK: - Cloud Model Card View
struct CloudModelCardView: View {
    let model: CloudModel
    let isCurrent: Bool
    var setDefaultAction: () -> Void
    
    @EnvironmentObject private var whisperState: WhisperState
    @StateObject private var aiService = AIService()
    @State private var isExpanded = false
    @State private var apiKey = ""
    @State private var isVerifying = false
    @State private var verificationStatus: VerificationStatus = .none
    @State private var isConfiguredState: Bool = false
    @State private var verificationError: String? = nil
    @State private var showGroqKeySteps: Bool = false
    
    enum VerificationStatus {
        case none, verifying, success, failure
    }
    
    private var isConfigured: Bool {
        guard let savedKey = UserDefaults.standard.string(forKey: "\(providerKey)APIKey") else {
            return false
        }
        return !savedKey.isEmpty
    }
    
    private var providerKey: String {
        switch model.provider {
        case .groq:
            return "GROQ"
        case .elevenLabs:
            return "ElevenLabs"
        case .deepgram:
            return "Deepgram"
        case .mistral:
            return "Mistral"
        case .gemini:
            return "Gemini"
        case .soniox:
            return "Soniox"
        default:
            return model.provider.rawValue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card content
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    headerSection
                    metadataSection
                    descriptionSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                actionSection
            }
            .padding(16)
            
            // Expandable configuration section
            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)
                
                configurationSection
                    .padding(16)
            }
        }
        .background(CardBackground(isSelected: isCurrent, useAccentGradientWhenSelected: isCurrent))
        .onAppear {
            loadSavedAPIKey()
            isConfiguredState = isConfigured
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(model.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.labelColor))
            
            statusBadge
            
            Spacer()
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            // Groq 모델에 "최고 정확도" 뱃지 표시
            if model.provider == .groq {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                    Text("최고 정확도")
                }
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundColor(.white)
            }
            
            if isCurrent {
                Text("기본")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundColor(.white)
            } else if isConfiguredState {
                Text("설정됨")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(.systemGreen).opacity(0.2)))
                    .foregroundColor(Color(.systemGreen))
            } else {
                Text("설정 필요")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(.systemOrange).opacity(0.2)))
                    .foregroundColor(Color(.systemOrange))
            }
        }
    }
    
    private var metadataSection: some View {
        HStack(spacing: 12) {
            // Provider
            Label(model.provider.rawValue, systemImage: "cloud")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabelColor))
                .lineLimit(1)
            
            // Language
            Label(model.language, systemImage: "globe")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabelColor))
                .lineLimit(1)
            
            Label("클라우드 모델", systemImage: "icloud")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabelColor))
                .lineLimit(1)
            
            // Accuracy
            HStack(spacing: 3) {
                Text("정확도")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(.secondaryLabelColor))
                progressDotsWithNumber(value: model.accuracy * 10)
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
        }
        .lineLimit(1)
    }
    
    private var descriptionSection: some View {
        Text(model.description)
            .font(.system(size: 11))
            .foregroundColor(Color(.secondaryLabelColor))
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }
    
    private var actionSection: some View {
        HStack(spacing: 8) {
            if isCurrent {
                Text("기본 모델")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabelColor))
            } else if isConfiguredState {
                HStack(spacing: 8) {
                    Button(action: setDefaultAction) {
                        Text("기본으로 설정")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(action: {
                        withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.secondaryLabelColor))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button(action: {
                    withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("설정")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "gear")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.2), radius: 2, x: 0, y: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            if isConfiguredState {
                Menu {
                    Button {
                        clearAPIKey()
                    } label: {
                        Label("API 키 제거", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 20, height: 20)
            }
        }
    }
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Groq 전용 안내 UI
            if model.provider == .groq {
                groqSetupGuideSection
                Divider()
            }
            
            Text("API 키 설정")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.labelColor))
            
            HStack(spacing: 8) {
                SecureField("\(model.provider.rawValue) API 키 입력", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isVerifying)
                
                // API 키가 설정된 상태일 때 제거 버튼 표시
                if isConfiguredState && !apiKey.isEmpty {
                    Button(action: clearAPIKey) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(.systemRed))
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: verifyAPIKey) {
                    HStack(spacing: 4) {
                        if isVerifying {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: verificationStatus == .success ? "checkmark" : "checkmark.shield")
                                .font(.system(size: 12, weight: .medium))
                        }
                        Text(isVerifying ? "확인 중..." : "확인")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(verificationStatus == .success ? Color(.systemGreen) : Color.accentColor)
                    )
                }
                .buttonStyle(.plain)
                .disabled(apiKey.isEmpty || isVerifying)
            }
            
            if verificationStatus == .failure {
                if let error = verificationError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Color(.systemRed))
                } else {
                    Text("확인 실패")
                        .font(.caption)
                        .foregroundColor(Color(.systemRed))
                }
            } else if verificationStatus == .success {
                Text("API 키 확인 성공!")
                    .font(.caption)
                    .foregroundColor(Color(.systemGreen))
            }
            
            // 보안 안내
            securityInfoSection
            
            // 오프라인 모델 전환 안내
            offlineModelSuggestionSection
        }
    }
    
    // MARK: - Groq Setup Guide
    @ViewBuilder
    private var groqSetupGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text("2–3분이면 설정 완료")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.labelColor))
            }
            
            HStack(spacing: 6) {
                groqInfoPill("무료")
                groqInfoPill("로컬 저장")
                groqInfoPill("외부 전송 없음")
                    .help("Badasugi 서버로 전송하지 않습니다. (Groq 인증에만 사용)")
            }
            
            if showGroqKeySteps {
                VStack(alignment: .leading, spacing: 4) {
                    Text("발급 방법")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(.labelColor))
                    
                    Text("1) Groq 로그인/가입")
                    Text("2) Console → API Keys → Create")
                    Text("3) 키 복사 → 아래 입력칸에 붙여넣기")
                }
                .font(.system(size: 12))
                .foregroundColor(Color(.secondaryLabelColor))
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("버튼을 누르면 Groq 콘솔이 열립니다.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabelColor))
            }
            
            Button(action: {
                if let url = URL(string: "https://console.groq.com/keys") {
                    NSWorkspace.shared.open(url)
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showGroqKeySteps = true
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("API 키 가져오기")
                        .font(.system(size: 12, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
        )
    }

    private func groqInfoPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(Color.blue)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.14))
            )
    }
    
    // MARK: - Security Info
    @ViewBuilder
    private var securityInfoSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(.systemGreen))
            Text("API 키는 이 기기에만 로컬로 저장되며, Badasugi 서버로 전송되지 않습니다.")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabelColor))
        }
        .padding(.top, 4)
    }
    
    // MARK: - Offline Model Suggestion
    @ViewBuilder
    private var offlineModelSuggestionSection: some View {
        if !isConfiguredState {
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabelColor))
                    Text("인터넷 없이 사용하고 싶다면?")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabelColor))
                    
                    Spacer()
                    
                    Button(action: {
                        // 오프라인 모델 섹션으로 안내
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SwitchToOfflineModels"),
                            object: nil
                        )
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded = false
                        }
                    }) {
                        Text("오프라인 모델 보기")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }
    
    private func loadSavedAPIKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "\(providerKey)APIKey") {
            apiKey = savedKey
            verificationStatus = .success
        }
    }
    
    private func verifyAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        isVerifying = true
        verificationStatus = .verifying
        
        switch model.provider {
        case .groq:
            aiService.selectedProvider = .groq
        case .elevenLabs:
            aiService.selectedProvider = .elevenLabs
        case .deepgram:
            aiService.selectedProvider = .deepgram
        case .mistral:
            aiService.selectedProvider = .mistral
        case .gemini:
            aiService.selectedProvider = .gemini
        case .soniox:
            aiService.selectedProvider = .soniox
        default:
            // This case should ideally not be hit for cloud models in this view
            print("Warning: verifyAPIKey called for unsupported provider \(model.provider.rawValue)")
            isVerifying = false
            verificationStatus = .failure
            return
        }
        
        aiService.saveAPIKey(apiKey) { isValid, errorMessage in
            DispatchQueue.main.async {
                self.isVerifying = false
                if isValid {
                    self.verificationStatus = .success
                    self.verificationError = nil
                    // Save the API key
                    UserDefaults.standard.set(self.apiKey, forKey: "\(self.providerKey)APIKey")
                    self.isConfiguredState = true
                    
                    // Collapse the configuration section after successful verification
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isExpanded = false
                    }
                } else {
                    self.verificationStatus = .failure
                    self.verificationError = errorMessage
                }
                
                // Restore original provider
                // aiService.selectedProvider = originalProvider // This line was removed as per the new_code
            }
        }
    }
    
    private func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: "\(providerKey)APIKey")
        apiKey = ""
        verificationStatus = .none
        verificationError = nil
        isConfiguredState = false
        
        // If this model is currently the default, clear it
        if isCurrent {
            Task {
                await MainActor.run {
                    whisperState.currentTranscriptionModel = nil
                    UserDefaults.standard.removeObject(forKey: "CurrentTranscriptionModel")
                }
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded = false
        }
    }
}
