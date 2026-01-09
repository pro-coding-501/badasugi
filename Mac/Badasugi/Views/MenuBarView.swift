import SwiftUI
import LaunchAtLogin

struct MenuBarView: View {
    @EnvironmentObject var whisperState: WhisperState
    @EnvironmentObject var hotkeyManager: HotkeyManager
    @EnvironmentObject var menuBarManager: MenuBarManager
    @EnvironmentObject var updaterViewModel: UpdaterViewModel
    @EnvironmentObject var enhancementService: AIEnhancementService
    @EnvironmentObject var aiService: AIService
    @ObservedObject var audioDeviceManager = AudioDeviceManager.shared
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @State private var menuRefreshTrigger = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 6) {
            Button("녹음기 토글") {
                whisperState.handleToggleMiniRecorder()
            }
            .controlSize(.large)

            Divider()

            Menu {
                ForEach(whisperState.usableModels, id: \.id) { model in
                    Button {
                        Task {
                            await whisperState.setDefaultTranscriptionModel(model)
                        }
                    } label: {
                        HStack {
                            Text(model.displayName)
                            if whisperState.currentTranscriptionModel?.id == model.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("모델 관리") {
                    menuBarManager.openMainWindowAndNavigate(to: "AI Models")
                }
            } label: {
                HStack {
                    Text("인식 모델: \(whisperState.currentTranscriptionModel?.displayName ?? "없음")")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                }
            }
            .controlSize(.large)
            
            Divider()
            
            Toggle("텍스트 다듬기", isOn: $enhancementService.isEnhancementEnabled)
                .controlSize(.large)
            
            Menu {
                ForEach(enhancementService.allPrompts) { prompt in
                    Button {
                        enhancementService.setActivePrompt(prompt)
                    } label: {
                        HStack {
                            Image(systemName: prompt.icon)
                                .foregroundColor(.accentColor)
                            Text(prompt.title)
                            if enhancementService.selectedPromptId == prompt.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("다듬기 스타일: \(enhancementService.activePrompt?.title ?? "없음")")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                }
            }
            .controlSize(.large)
            
            Menu {
                ForEach(aiService.connectedProviders, id: \.self) { provider in
                    Button {
                        aiService.selectedProvider = provider
                    } label: {
                        HStack {
                            Text(provider.rawValue)
                            if aiService.selectedProvider == provider {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                if aiService.connectedProviders.isEmpty {
                    Text("연결된 제공업체 없음")
                        .foregroundColor(.secondary)
                }
            } label: {
                HStack {
                    Text("AI 제공업체: \(aiService.selectedProvider.rawValue)")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                }
            }
            .controlSize(.large)
            
            Menu {
                ForEach(aiService.availableModels, id: \.self) { model in
                    Button {
                        aiService.selectModel(model)
                    } label: {
                        HStack {
                            Text(model)
                            if aiService.currentModel == model {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                if aiService.availableModels.isEmpty {
                    Text("사용 가능한 모델 없음")
                        .foregroundColor(.secondary)
                }
            } label: {
                HStack {
                    Text("AI 모델: \(aiService.currentModel)")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                }
            }
            .controlSize(.large)
            
            LanguageSelectionView(whisperState: whisperState, displayMode: .menuItem, whisperPrompt: whisperState.whisperPrompt)

            Menu {
                ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                    Button {
                        audioDeviceManager.selectDeviceAndSwitchToCustomMode(id: device.id)
                    } label: {
                        HStack {
                            Text(device.name)
                            if audioDeviceManager.getCurrentDevice() == device.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                if audioDeviceManager.availableDevices.isEmpty {
                    Text("사용 가능한 장치 없음")
                        .foregroundColor(.secondary)
                }
            } label: {
                HStack {
                    Text("오디오 입력")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                }
            }
            .controlSize(.large)

            Menu("추가") {
                Button {
                    enhancementService.useClipboardContext.toggle()
                    menuRefreshTrigger.toggle()
                } label: {
                    HStack {
                        Text("클립보드 컨텍스트")
                        Spacer()
                        if enhancementService.useClipboardContext {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    enhancementService.useScreenCaptureContext.toggle()
                    menuRefreshTrigger.toggle()
                } label: {
                    HStack {
                        Text("컨텍스트 인식")
                        Spacer()
                        if enhancementService.useScreenCaptureContext {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .id("additional-menu-\(menuRefreshTrigger)")
            .controlSize(.large)
            
            Divider()

            Button("마지막 기록 다시 시도") {
                LastTranscriptionService.retryLastTranscription(from: whisperState.modelContext, whisperState: whisperState)
            }
            .controlSize(.large)
            
            Button("마지막 기록 복사") {
                LastTranscriptionService.copyLastTranscription(from: whisperState.modelContext)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .controlSize(.large)
            
            Button("설정") {
                menuBarManager.openMainWindowAndNavigate(to: "Settings")
            }
            .keyboardShortcut(",", modifiers: .command)
            .controlSize(.large)
            
            Button(menuBarManager.isMenuBarOnly ? "독 아이콘 표시" : "독 아이콘 숨기기") {
                menuBarManager.toggleMenuBarOnly()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .controlSize(.large)
            
            Toggle("로그인 시 시작", isOn: $launchAtLoginEnabled)
                .onChange(of: launchAtLoginEnabled) { oldValue, newValue in
                    LaunchAtLogin.isEnabled = newValue
                }
                .controlSize(.large)
            
            Divider()
            
            Button("업데이트 확인") {
                updaterViewModel.checkForUpdates()
            }
            .disabled(!updaterViewModel.canCheckForUpdates)
            .controlSize(.large)
            
            Button("도움말 및 지원") {
                EmailSupport.openSupportEmail()
            }
            .controlSize(.large)
            
            Divider()

            Button("받아쓰기 종료") {
                NSApplication.shared.terminate(nil)
            }
            .controlSize(.large)
        }
    }
}