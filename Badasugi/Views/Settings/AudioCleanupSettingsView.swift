import SwiftUI
import SwiftData

struct AudioCleanupSettingsView: View {
    @EnvironmentObject private var whisperState: WhisperState
    
    // Audio cleanup settings
    @AppStorage("IsTranscriptionCleanupEnabled") private var isTranscriptionCleanupEnabled = false
    @AppStorage("TranscriptionRetentionMinutes") private var transcriptionRetentionMinutes = 24 * 60
    @AppStorage("IsAudioCleanupEnabled") private var isAudioCleanupEnabled = false
    @AppStorage("AudioRetentionPeriod") private var audioRetentionPeriod = 7
    @State private var isPerformingCleanup = false
    @State private var isShowingConfirmation = false
    @State private var cleanupInfo: (fileCount: Int, totalSize: Int64, transcriptions: [Transcription]) = (0, 0, [])
    @State private var showResultAlert = false
    @State private var cleanupResult: (deletedCount: Int, errorCount: Int) = (0, 0)
    @State private var showTranscriptCleanupResult = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("개인정보 보호 및 저장소 관리를 위해 받아쓰기가 기록 데이터와 오디오 녹음을 처리하는 방법을 제어합니다.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Toggle("기록 자동 삭제", isOn: $isTranscriptionCleanupEnabled)
                .toggleStyle(.switch)
                .padding(.vertical, 4)
            
            if isTranscriptionCleanupEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("다음보다 오래된 기록 삭제", selection: $transcriptionRetentionMinutes) {
                        Text("즉시").tag(0)
                        Text("1시간").tag(60)
                        Text("1일").tag(24 * 60)
                        Text("3일").tag(3 * 24 * 60)
                        Text("7일").tag(7 * 24 * 60)
                    }
                    .pickerStyle(.menu)

                    Text("선택한 설정에 따라 오래된 기록이 자동으로 삭제됩니다.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)

                    Button(action: {
                        Task {
                            await TranscriptionAutoCleanupService.shared.runManualCleanup(modelContext: whisperState.modelContext)
                            await MainActor.run {
                                showTranscriptCleanupResult = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash.circle")
                            Text("지금 기록 정리 실행")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .alert("기록 정리", isPresented: $showTranscriptCleanupResult) {
                        Button("확인", role: .cancel) { }
                    } message: {
                        Text("정리가 시작되었습니다. 오래된 기록이 보관 설정에 따라 정리됩니다.")
                    }
                }
                .padding(.vertical, 4)
            }

            if !isTranscriptionCleanupEnabled {
                Toggle("자동 오디오 정리 활성화", isOn: $isAudioCleanupEnabled)
                    .toggleStyle(.switch)
                    .padding(.vertical, 4)
            }

            if isAudioCleanupEnabled && !isTranscriptionCleanupEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("오디오 파일 보관 기간", selection: $audioRetentionPeriod) {
                        Text("1일").tag(1)
                        Text("3일").tag(3)
                        Text("7일").tag(7)
                        Text("14일").tag(14)
                        Text("30일").tag(30)
                    }
                    .pickerStyle(.menu)
                    
                    Text("선택한 기간보다 오래된 오디오 파일은 자동으로 삭제되며, 텍스트 기록은 그대로 유지됩니다.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
                .padding(.vertical, 4)
                
                Button(action: {
                    // Start by analyzing what would be cleaned up
                    Task {
                        // Update UI state
                        await MainActor.run {
                            isPerformingCleanup = true
                        }
                        
                        // Get cleanup info
                        let info = await AudioCleanupManager.shared.getCleanupInfo(modelContext: whisperState.modelContext)
                        
                        // Update UI with results
                        await MainActor.run {
                            cleanupInfo = info
                            isPerformingCleanup = false
                            isShowingConfirmation = true
                        }
                    }
                }) {
                    HStack {
                        if isPerformingCleanup {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isPerformingCleanup ? "분석 중..." : "지금 정리 실행")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isPerformingCleanup)
                .alert("오디오 정리", isPresented: $isShowingConfirmation) {
                    Button("취소", role: .cancel) { }
                    
                    if cleanupInfo.fileCount > 0 {
                        Button("\(cleanupInfo.fileCount)개 파일 삭제", role: .destructive) {
                            Task {
                                // Update UI state
                                await MainActor.run {
                                    isPerformingCleanup = true
                                }
                                
                                // Perform cleanup
                                let result = await AudioCleanupManager.shared.runCleanupForTranscriptions(
                                    modelContext: whisperState.modelContext, 
                                    transcriptions: cleanupInfo.transcriptions
                                )
                                
                                // Update UI with results
                                await MainActor.run {
                                    cleanupResult = result
                                    isPerformingCleanup = false
                                    showResultAlert = true
                                }
                            }
                        }
                    }
                } message: {
                    VStack(alignment: .leading, spacing: 8) {
                        if cleanupInfo.fileCount > 0 {
                            Text("\(audioRetentionPeriod)일보다 오래된 오디오 파일 \(cleanupInfo.fileCount)개가 삭제됩니다.")
                            Text("해제될 총 크기: \(AudioCleanupManager.shared.formatFileSize(cleanupInfo.totalSize))")
                            Text("텍스트 기록은 보존됩니다.")
                        } else {
                            Text("\(audioRetentionPeriod)일보다 오래된 오디오 파일을 찾을 수 없습니다.")
                        }
                    }
                }
                .alert("정리 완료", isPresented: $showResultAlert) {
                    Button("확인", role: .cancel) { }
                } message: {
                    if cleanupResult.errorCount > 0 {
                        Text("오디오 파일 \(cleanupResult.deletedCount)개를 성공적으로 삭제했습니다. \(cleanupResult.errorCount)개 파일 삭제에 실패했습니다.")
                    } else {
                        Text("오디오 파일 \(cleanupResult.deletedCount)개를 성공적으로 삭제했습니다.")
                    }
                }
            }
        }
        .onChange(of: isTranscriptionCleanupEnabled) { _, newValue in
            if newValue {
                AudioCleanupManager.shared.stopAutomaticCleanup()
            } else if isAudioCleanupEnabled {
                AudioCleanupManager.shared.startAutomaticCleanup(modelContext: whisperState.modelContext)
            }
        }
    }
} 