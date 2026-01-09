import Foundation
import SwiftUI

@MainActor
extension WhisperState {
    // MARK: - Model Loading
    
    /// 저장된 모델을 불러오거나, 없으면 스마트 기본값을 설정
    func loadCurrentTranscriptionModel() {
        // 1) 사용자가 직접 선택한 모델이 있으면 그것을 사용 (앱 재시작 후에도 유지)
        if let savedModelName = UserDefaults.standard.string(forKey: "CurrentTranscriptionModel"),
           let savedModel = allAvailableModels.first(where: { $0.name == savedModelName }) {
            currentTranscriptionModel = savedModel
            return
        }
        
        // 2) 저장된 모델이 없으면 스마트 기본값 설정
        selectSmartDefaultModel()
    }
    
    /// Groq API 키 유무에 따라 스마트 기본 모델 선택
    private func selectSmartDefaultModel() {
        let hasGroqAPIKey = {
            if let apiKey = UserDefaults.standard.string(forKey: "GROQAPIKey"), !apiKey.isEmpty {
                return true
            }
            return false
        }()
        
        if hasGroqAPIKey {
            // Groq API 키가 있으면 Groq 클라우드 모델을 기본으로
            if let groqModel = allAvailableModels.first(where: { $0.name == "whisper-large-v3-turbo" }) {
                currentTranscriptionModel = groqModel
                UserDefaults.standard.set(groqModel.name, forKey: "CurrentTranscriptionModel")
                return
            }
        }
        
        // Groq API 키가 없거나 Groq 모델을 찾을 수 없으면 로컬 모델을 기본으로
        // 다운로드된 로컬 모델이 있으면 그것을 사용
        if let downloadedLocalModel = availableModels.first(where: { $0.name == "ggml-large-v3-turbo" }),
           let localModel = allAvailableModels.first(where: { $0.name == downloadedLocalModel.name }) {
            currentTranscriptionModel = localModel
            UserDefaults.standard.set(localModel.name, forKey: "CurrentTranscriptionModel")
            return
        }
        
        // 다운로드된 Large v3 Turbo가 없으면 Quantized 버전 확인
        if let downloadedQuantizedModel = availableModels.first(where: { $0.name == "ggml-large-v3-turbo-q5_0" }),
           let quantizedModel = allAvailableModels.first(where: { $0.name == downloadedQuantizedModel.name }) {
            currentTranscriptionModel = quantizedModel
            UserDefaults.standard.set(quantizedModel.name, forKey: "CurrentTranscriptionModel")
            return
        }
        
        // 아무 로컬 모델도 없으면 Large v3 Turbo를 기본 선택 (다운로드 필요 상태)
        if let localModel = allAvailableModels.first(where: { $0.name == "ggml-large-v3-turbo" }) {
            currentTranscriptionModel = localModel
            UserDefaults.standard.set(localModel.name, forKey: "CurrentTranscriptionModel")
        }
    }

    // MARK: - Model Selection
    
    /// 사용자가 직접 선택한 모델을 기본으로 설정 (앱 재시작 후에도 유지됨)
    func setDefaultTranscriptionModel(_ model: any TranscriptionModel) {
        self.currentTranscriptionModel = model
        UserDefaults.standard.set(model.name, forKey: "CurrentTranscriptionModel")
        
        // For cloud models, clear the old loadedLocalModel
        if model.provider != .local {
            self.loadedLocalModel = nil
        }
        
        // Enable transcription for cloud models immediately since they don't need loading
        if model.provider != .local {
            self.isModelLoaded = true
        }
        // Post notification about the model change
        NotificationCenter.default.post(name: .didChangeModel, object: nil, userInfo: ["modelName": model.name])
        NotificationCenter.default.post(name: .AppSettingsDidChange, object: nil)
    }
    
    // MARK: - Model Refresh
    
    func refreshAllAvailableModels() {
        let currentModelName = currentTranscriptionModel?.name
        var models = PredefinedModels.models

        // Append dynamically discovered local models (imported .bin files) with minimal metadata
        for whisperModel in availableModels {
            if !models.contains(where: { $0.name == whisperModel.name }) {
                let importedModel = ImportedLocalModel(fileBaseName: whisperModel.name)
                models.append(importedModel)
            }
        }

        allAvailableModels = models

        // Preserve current selection by name (IDs may change for dynamic models)
        if let currentName = currentModelName,
           let updatedModel = allAvailableModels.first(where: { $0.name == currentName }) {
            setDefaultTranscriptionModel(updatedModel)
        }
    }
} 