import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct ModelManagementView: View {
    @ObservedObject var whisperState: WhisperState
    @State private var customModelToEdit: CustomCloudModel?
    @StateObject private var aiService = AIService()
    @StateObject private var customModelManager = CustomModelManager.shared
    @EnvironmentObject private var enhancementService: AIEnhancementService
    @Environment(\.modelContext) private var modelContext
    @StateObject private var whisperPrompt = WhisperPrompt()
    @ObservedObject private var warmupCoordinator = WhisperModelWarmupCoordinator.shared

    @State private var isShowingSettings = false
    @State private var isAdvancedExpanded = false
    
    // State for the unified alert
    @State private var isShowingDeleteAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var deleteActionClosure: () -> Void = {}
    
    // Groq API key (saved locally)
    @AppStorage("GROQAPIKey") private var groqAPIKey: String = ""
    @State private var groqAPIKeyDraft: String = ""
    @State private var groqSaveMessage: String? = nil
    @State private var isShowingGroqKeyGuide: Bool = false
    
    private var hasGroqAPIKey: Bool {
        !groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section header
                VStack(alignment: .leading, spacing: 8) {
                    Text("음성 인식")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("음성을 텍스트로 변환할 모델을 선택하세요")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // 간소화된 모델 선택 섹션
                modelSelectionSection
                
                // Language selection (simple)
                languageSelectionSection
                
                // Advanced settings (collapsed)
                advancedSettingsSection
            }
            .padding(40)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                primaryButton: .destructive(Text("삭제"), action: deleteActionClosure),
                secondaryButton: .cancel(Text("취소"))
            )
        }
        .onAppear {
            groqAPIKeyDraft = groqAPIKey
        }
    }
    
    // MARK: - Remove Groq API Key
    private func removeGroqAPIKey() {
        groqAPIKey = ""
        groqAPIKeyDraft = ""
        groqSaveMessage = nil
        
        // 현재 선택된 모델이 Groq이면 선택 해제
        if whisperState.currentTranscriptionModel?.provider == .groq {
            whisperState.currentTranscriptionModel = nil
            UserDefaults.standard.removeObject(forKey: "CurrentTranscriptionModel")
        }
    }
    
    private func saveGroqAPIKey() {
        let trimmed = groqAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        groqAPIKey = trimmed
        groqSaveMessage = trimmed.isEmpty ? "API 키가 비어있어 저장되지 않았습니다." : "Groq API 키가 저장되었습니다."
        
        // If user just added a key and no model is selected, pick a smart default (Groq first).
        if !trimmed.isEmpty, whisperState.currentTranscriptionModel == nil {
            whisperState.loadCurrentTranscriptionModel()
        }
    }
    
    // MARK: - Model Selection Section (간소화됨)
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("모델 선택")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                ForEach(Array(availableModels.enumerated()), id: \.element.id) { index, model in
                    SimpleModelRow(
                        model: model,
                        isSelected: whisperState.currentTranscriptionModel?.name == model.name,
                        isDownloaded: isModelDownloaded(model),
                        isDownloading: whisperState.downloadProgress[model.name] != nil,
                        downloadProgress: whisperState.downloadProgress[model.name] ?? 0,
                        hasGroqAPIKey: hasGroqAPIKey,
                        isWarming: (model as? LocalModel).map { warmupCoordinator.isWarming(modelNamed: $0.name) } ?? false,
                        selectAction: {
                            Task {
                                await whisperState.setDefaultTranscriptionModel(model)
                            }
                        },
                        downloadAction: {
                            if let localModel = model as? LocalModel {
                                Task { await whisperState.downloadModel(localModel) }
                            }
                        },
                        removeAPIKeyAction: model.provider == .groq ? {
                            removeGroqAPIKey()
                        } : nil
                    )
                    
                    if index < availableModels.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            
            groqAPIKeyInlineSection
        }
    }
    
    private var groqAPIKeyInlineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundColor(.blue)
                Text("Whisper Large v3 Turbo (Groq) API 키")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                
                if !hasGroqAPIKey {
                    Button("API 키 가져오기") {
                        if let url = URL(string: "https://console.groq.com/keys") {
                            NSWorkspace.shared.open(url)
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingGroqKeyGuide = true
                        }
                    }
                    .font(.caption)
                }
            }
            
            HStack(spacing: 6) {
                groqInfoPill("무료")
                groqInfoPill("로컬 저장")
                groqInfoPill("외부 전송 없음")
                    .help("Badasugi 서버로 전송하지 않습니다. (Groq 인증에만 사용)")
            }
            
            if !hasGroqAPIKey {
                if isShowingGroqKeyGuide {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("발급 방법 (2–3분)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("1) Groq 로그인/가입")
                        Text("2) Console → API Keys → Create")
                        Text("3) 키 복사 → 여기 붙여넣고 저장")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
                } else {
                    Text("버튼을 누르면 Groq 콘솔이 열립니다. 2–3분이면 끝!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    SecureField("Groq API 키 입력", text: $groqAPIKeyDraft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { saveGroqAPIKey() }
                    
                    Button("저장") {
                        saveGroqAPIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(groqAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                Text("키는 이 Mac에만 저장되며, Badasugi 서버로 전송되지 않습니다.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let message = groqSaveMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Groq API 키를 등록하면 최고 정확도의 클라우드 모델을 무료로 사용할 수 있습니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // API 키가 저장되어 있을 때는 간단한 상태 표시와 삭제 버튼만
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("API 키가 등록되었습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Groq 모델 사용") {
                        if let groqModel = whisperState.allAvailableModels.first(where: { $0.name == "whisper-large-v3-turbo" }) {
                            Task { await whisperState.setDefaultTranscriptionModel(groqModel) }
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        removeGroqAPIKey()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("제거")
                        }
                    }
                    .buttonStyle(.bordered)
                    .help("API 키 제거")
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(8)
        .onAppear {
            // Keep draft in sync if coming back to this screen.
            groqAPIKeyDraft = groqAPIKey
        }
        .onChange(of: groqAPIKey) { _, newValue in
            // Sync draft if key was changed elsewhere.
            if newValue != groqAPIKeyDraft {
                groqAPIKeyDraft = newValue
            }
        }
    }

    private func groqInfoPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(Color.blue)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.14))
            )
    }
    
    // 표시할 모델 목록 (4개 고정)
    private var availableModels: [any TranscriptionModel] {
        // 기본 4개 모델만 표시
        let modelNames = ["whisper-large-v3-turbo", "ggml-large-v3-turbo", "ggml-large-v3-turbo-q5_0", "apple-speech"]
        return whisperState.allAvailableModels.filter { modelNames.contains($0.name) }
            .sorted { model1, model2 in
                let order = modelNames
                let index1 = order.firstIndex(of: model1.name) ?? Int.max
                let index2 = order.firstIndex(of: model2.name) ?? Int.max
                return index1 < index2
            }
    }
    
    private func isModelDownloaded(_ model: any TranscriptionModel) -> Bool {
        // 클라우드 모델과 네이티브 모델은 항상 사용 가능
        if model.provider == .groq || model.provider == .nativeApple {
            return true
        }
        // 로컬 모델은 다운로드 여부 확인
        return whisperState.availableModels.contains { $0.name == model.name }
    }
    
    private var languageSelectionSection: some View {
        LanguageSelectionView(whisperState: whisperState, displayMode: .full, whisperPrompt: whisperPrompt)
    }
    
    private var advancedSettingsSection: some View {
        DisclosureGroup(isExpanded: $isAdvancedExpanded) {
            VStack(alignment: .leading, spacing: 20) {
                // Current model display (read-only)
                HStack {
                    Text("현재 모델")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(whisperState.currentTranscriptionModel?.displayName ?? "선택 안 됨")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Model settings
                ModelSettingsView(whisperPrompt: whisperPrompt)
                
                Divider()
                
                // Import local model button
                HStack(spacing: 8) {
                    Button(action: { presentImportPanel() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                            Text("커스텀 로컬 모델 가져오기…")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(CardBackground(isSelected: false))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    InfoTip(
                        title: "커스텀 Whisper 모델 가져오기",
                        message: "직접 파인튜닝한 Whisper 모델을 추가할 수 있습니다. .bin 파일을 선택하세요.",
                        learnMoreURL: "https://www.badasugi.com"
                    )
                    .help("커스텀 로컬 모델에 대해 자세히 알아보기")
                }
                
                // 사용자 지정 모델 섹션 (있는 경우에만 표시)
                if !customModelManager.customModels.isEmpty {
                    Divider()
                    
                    Text("사용자 지정 모델")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(customModelManager.customModels, id: \.id) { customModel in
                        CustomModelCardRowView(
                            model: customModel,
                            whisperState: whisperState,
                            isCurrent: whisperState.currentTranscriptionModel?.name == customModel.name,
                            onDelete: {
                                alertTitle = "사용자 지정 모델 삭제"
                                alertMessage = "'\(customModel.displayName)'을(를) 삭제하시겠습니까?"
                                deleteActionClosure = {
                                    customModelManager.removeCustomModel(withId: customModel.id)
                                    whisperState.refreshAllAvailableModels()
                                }
                                isShowingDeleteAlert = true
                            },
                            onEdit: { model in
                                customModelToEdit = model
                            },
                            onSelect: {
                                Task {
                                    await whisperState.setDefaultTranscriptionModel(customModel)
                                }
                            }
                        )
                    }
                }
                
                // Add Custom Model Card
                AddCustomModelCardView(
                    customModelManager: customModelManager,
                    editingModel: customModelToEdit
                ) {
                    whisperState.refreshAllAvailableModels()
                    customModelToEdit = nil
                }
            }
            .padding(.top, 12)
        } label: {
            HStack {
                Image(systemName: "gearshape")
                    .foregroundColor(.secondary)
                Text("고급 설정")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .padding()
        .background(CardBackground(isSelected: false))
        .cornerRadius(10)
    }

    // MARK: - Import Panel
    private func presentImportPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "bin")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.title = "Whisper ggml .bin 모델 선택"
        if panel.runModal() == .OK, let url = panel.url {
            Task { @MainActor in
                await whisperState.importLocalModel(from: url)
            }
        }
    }
}

// MARK: - Simple Model Row (간소화된 모델 행)
private struct SimpleModelRow: View {
    let model: any TranscriptionModel
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let hasGroqAPIKey: Bool
    let isWarming: Bool
    let selectAction: () -> Void
    let downloadAction: () -> Void
    var removeAPIKeyAction: (() -> Void)? = nil
    
    @State private var isHovering = false
    
    private var isAvailable: Bool {
        // Groq 모델은 API 키가 있어야 사용 가능
        if model.provider == .groq {
            return hasGroqAPIKey
        }
        // 로컬 모델은 다운로드가 되어 있어야 사용 가능
        if model.provider == .local {
            return isDownloaded
        }
        // Apple Speech는 항상 사용 가능
        return true
    }
    
    private var modelIcon: String {
        switch model.provider {
        case .groq:
            return "cloud.fill"
        case .local:
            return "desktopcomputer"
        case .nativeApple:
            return "apple.logo"
        default:
            return "questionmark.circle"
        }
    }
    
    private var statusText: String {
        if model.provider == .groq && !hasGroqAPIKey {
            return "API 키 필요"
        }
        if model.provider == .local && !isDownloaded {
            return "다운로드 필요"
        }
        if isWarming {
            return "준비 중..."
        }
        return ""
    }
    
    private var recommendationBadge: String? {
        if model.name == "whisper-large-v3-turbo" {
            return "추천"
        }
        if model.name == "ggml-large-v3-turbo" {
            return "오프라인"
        }
        if model.name == "ggml-large-v3-turbo-q5_0" {
            return "경량"
        }
        return nil
    }
    
    var body: some View {
        Button(action: {
            if isAvailable && !isDownloading {
                selectAction()
            } else if model.provider == .local && !isDownloaded && !isDownloading {
                downloadAction()
            }
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: modelIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    )
                
                // Title and description
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(model.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if let badge = recommendationBadge {
                            Text(badge)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    model.name == "whisper-large-v3-turbo" ? Color.blue :
                                    model.name == "ggml-large-v3-turbo" ? Color.green :
                                    Color.orange
                                )
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(model.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Status / Actions
                if isDownloading {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 60)
                } else if !statusText.isEmpty {
                    if model.provider == .local && !isDownloaded {
                        Button(action: downloadAction) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle")
                                Text("다운로드")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(statusText)
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                
                // Groq API 키 제거 버튼 (API 키가 있을 때만 표시)
                if model.provider == .groq && hasGroqAPIKey, let removeAction = removeAPIKeyAction {
                    Button(action: removeAction) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("API 키 제거")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHovering && isAvailable ? Color.primary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable && model.provider != .local)
        .opacity(isAvailable || model.provider == .local ? 1.0 : 0.6)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
