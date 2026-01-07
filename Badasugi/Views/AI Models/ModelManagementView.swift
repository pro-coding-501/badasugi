import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

// 3-mode recognition mode for simplified UI
enum RecognitionMode: String, CaseIterable, Identifiable {
    case standard = "기본"
    case highAccuracy = "고정확"
    case offline = "오프라인"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .standard: return "빠르고 정확한 인식"
        case .highAccuracy: return "최고 정확도, 더 느림"
        case .offline: return "인터넷 없이 사용"
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "bolt.fill"
        case .highAccuracy: return "target"
        case .offline: return "wifi.slash"
        }
    }
}

enum ModelFilter: String, CaseIterable, Identifiable {
    case recommended = "추천"
    case local = "로컬"
    case cloud = "클라우드"
    case custom = "사용자 지정"
    var id: String { self.rawValue }
}

struct ModelManagementView: View {
    @ObservedObject var whisperState: WhisperState
    @State private var customModelToEdit: CustomCloudModel?
    @StateObject private var aiService = AIService()
    @StateObject private var customModelManager = CustomModelManager.shared
    @EnvironmentObject private var enhancementService: AIEnhancementService
    @Environment(\.modelContext) private var modelContext
    @StateObject private var whisperPrompt = WhisperPrompt()
    @ObservedObject private var warmupCoordinator = WhisperModelWarmupCoordinator.shared

    @State private var selectedFilter: ModelFilter = .recommended
    @State private var isShowingSettings = false
    @State private var isAdvancedExpanded = false
    @State private var selectedRecognitionMode: RecognitionMode = .standard
    
    // State for the unified alert
    @State private var isShowingDeleteAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var deleteActionClosure: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section header
                VStack(alignment: .leading, spacing: 8) {
                    Text("음성 인식")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("음성을 텍스트로 변환하는 방식을 선택하세요")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Primary: 3-mode selection
                recognitionModeSection
                
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
            // Set initial mode based on current model
            updateRecognitionModeFromCurrentModel()
        }
    }
    
    private var recognitionModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("인식 방식")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                ForEach(Array(RecognitionMode.allCases.enumerated()), id: \.element.id) { index, mode in
                    RecognitionModeListRow(
                        mode: mode,
                        isSelected: selectedRecognitionMode == mode,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedRecognitionMode = mode
                                applyRecognitionMode(mode)
                            }
                        }
                    )
                    
                    if index < RecognitionMode.allCases.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
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
                
                // Model management section
                availableModelsSection
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
    
    private var availableModelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Modern compact pill switcher
                HStack(spacing: 12) {
                    ForEach(ModelFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedFilter = filter
                                isShowingSettings = false
                            }
                        }) {
                            Text(filter.rawValue)
                                .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .medium))
                                .foregroundColor(selectedFilter == filter ? .primary : .primary.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    CardBackground(isSelected: selectedFilter == filter, cornerRadius: 22)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingSettings.toggle()
                    }
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isShowingSettings ? .accentColor : .primary.opacity(0.7))
                        .padding(12)
                        .background(
                            CardBackground(isSelected: isShowingSettings, cornerRadius: 22)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 12)
            
            if isShowingSettings {
                ModelSettingsView(whisperPrompt: whisperPrompt)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredModels, id: \.id) { model in
                        let isWarming = (model as? LocalModel).map { localModel in
                            warmupCoordinator.isWarming(modelNamed: localModel.name)
                        } ?? false

                        ModelCardRowView(
                            model: model,
                            whisperState: whisperState, 
                            isDownloaded: whisperState.availableModels.contains { $0.name == model.name },
                            isCurrent: whisperState.currentTranscriptionModel?.name == model.name,
                            downloadProgress: whisperState.downloadProgress,
                            modelURL: whisperState.availableModels.first { $0.name == model.name }?.url,
                            isWarming: isWarming,
                            deleteAction: {
                                if let customModel = model as? CustomCloudModel {
                                    alertTitle = "사용자 지정 모델 삭제"
                                    alertMessage = "사용자 지정 모델 '\(customModel.displayName)'을(를) 삭제하시겠습니까?"
                                    deleteActionClosure = {
                                        customModelManager.removeCustomModel(withId: customModel.id)
                                        whisperState.refreshAllAvailableModels()
                                    }
                                    isShowingDeleteAlert = true
                                } else if let downloadedModel = whisperState.availableModels.first(where: { $0.name == model.name }) {
                                    alertTitle = "모델 삭제"
                                    alertMessage = "모델 '\(downloadedModel.name)'을(를) 삭제하시겠습니까?"
                                    deleteActionClosure = {
                                        Task {
                                            await whisperState.deleteModel(downloadedModel)
                                        }
                                    }
                                    isShowingDeleteAlert = true
                                }
                            },
                            setDefaultAction: {
                                Task {
                                    await whisperState.setDefaultTranscriptionModel(model)
                                }
                            },
                            downloadAction: {
                                if let localModel = model as? LocalModel {
                                    Task { await whisperState.downloadModel(localModel) }
                                }
                            },
                            editAction: model.provider == .custom ? { customModel in
                                customModelToEdit = customModel
                            } : nil
                        )
                    }
                    
                    // Import button as a card at the end of the Local list
                    if selectedFilter == .local {
                        HStack(spacing: 8) {
                            Button(action: { presentImportPanel() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("로컬 모델 가져오기…")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(CardBackground(isSelected: false))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)

                            InfoTip(
                                title: "로컬 Whisper 모델 가져오기",
                                message: "받아쓰기에서 사용할 사용자 지정 파인튜닝 Whisper 모델을 추가합니다. 다운로드한 .bin 파일을 선택하세요.",
                                learnMoreURL: "https://tryvoiceink.com/docs/custom-local-whisper-models"
                            )
                            .help("사용자 지정 로컬 모델에 대해 자세히 알아보기")
                        }
                    }
                    
                    if selectedFilter == .custom {
                        // Add Custom Model Card at the bottom
                        AddCustomModelCardView(
                            customModelManager: customModelManager,
                            editingModel: customModelToEdit
                        ) {
                            // Refresh the models when a new custom model is added
                            whisperState.refreshAllAvailableModels()
                            customModelToEdit = nil // Clear editing state
                        }
                    }
                }
            }
        }
    }

    private var filteredModels: [any TranscriptionModel] {
        switch selectedFilter {
        case .recommended:
            return whisperState.allAvailableModels.filter {
                let recommendedNames = ["ggml-base.en", "ggml-large-v3-turbo-q5_0", "ggml-large-v3-turbo", "whisper-large-v3-turbo"]
                return recommendedNames.contains($0.name)
            }.sorted { model1, model2 in
                let recommendedOrder = ["ggml-base.en", "ggml-large-v3-turbo-q5_0", "ggml-large-v3-turbo", "whisper-large-v3-turbo"]
                let index1 = recommendedOrder.firstIndex(of: model1.name) ?? Int.max
                let index2 = recommendedOrder.firstIndex(of: model2.name) ?? Int.max
                return index1 < index2
            }
        case .local:
            return whisperState.allAvailableModels.filter { $0.provider == .local || $0.provider == .nativeApple || $0.provider == .parakeet }
        case .cloud:
            let cloudProviders: [ModelProvider] = [.groq, .elevenLabs, .deepgram, .mistral, .gemini, .soniox]
            return whisperState.allAvailableModels.filter { cloudProviders.contains($0.provider) }
        case .custom:
            return whisperState.allAvailableModels.filter { $0.provider == .custom }
        }
    }
    
    // MARK: - Recognition Mode Logic
    private func updateRecognitionModeFromCurrentModel() {
        guard let currentModel = whisperState.currentTranscriptionModel else { return }
        
        // Determine mode based on current model characteristics
        let cloudProviders: [ModelProvider] = [.groq, .elevenLabs, .deepgram, .mistral, .gemini, .soniox]
        
        if cloudProviders.contains(currentModel.provider) {
            // Cloud models = standard (fast)
            selectedRecognitionMode = .standard
        } else if currentModel.name.contains("large") && !currentModel.name.contains("turbo") {
            // Large non-turbo = high accuracy
            selectedRecognitionMode = .highAccuracy
        } else if currentModel.provider == .local || currentModel.provider == .nativeApple || currentModel.provider == .parakeet {
            // Local models = offline
            selectedRecognitionMode = .offline
        } else {
            selectedRecognitionMode = .standard
        }
    }
    
    private func applyRecognitionMode(_ mode: RecognitionMode) {
        // Find appropriate model for the selected mode
        let targetModel: (any TranscriptionModel)?
        
        switch mode {
        case .standard:
            // Prefer cloud turbo model or fast local
            targetModel = whisperState.allAvailableModels.first { $0.name == "whisper-large-v3-turbo" }
                ?? whisperState.allAvailableModels.first { $0.name == "ggml-large-v3-turbo-q5_0" }
        case .highAccuracy:
            // Prefer large model without turbo
            targetModel = whisperState.allAvailableModels.first { $0.name == "ggml-large-v3-turbo" }
                ?? whisperState.allAvailableModels.first { $0.name.contains("large") }
        case .offline:
            // Prefer downloaded local models only (exclude nativeApple which requires macOS 26+)
            targetModel = whisperState.allAvailableModels.first { model in
                (model.provider == .local || model.provider == .parakeet) &&
                whisperState.availableModels.contains { downloaded in downloaded.name == model.name }
            } ?? whisperState.allAvailableModels.first { $0.name == "ggml-large-v3-turbo-q5_0" }
        }
        
        if let model = targetModel {
            Task {
                await whisperState.setDefaultTranscriptionModel(model)
            }
        }
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

// MARK: - Recognition Mode List Row
private struct RecognitionModeListRow: View {
    let mode: RecognitionMode
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    )
                
                // Title and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(mode.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Checkmark when selected
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHovering ? Color.primary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
