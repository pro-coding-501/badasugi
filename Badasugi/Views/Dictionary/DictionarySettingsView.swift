import SwiftUI
import SwiftData

struct DictionarySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedSection: DictionarySection = .replacements
    let whisperPrompt: WhisperPrompt
    
    enum DictionarySection: String, CaseIterable {
        case replacements = "자동으로 바꾸기"
        case spellings = "단어 추가"
        
        var description: String {
            switch self {
            case .spellings:
                return "자주 쓰는 단어를 추가하여 인식률 향상"
            case .replacements:
                return "특정 단어를 원하는 형태로 자동 교정"
            }
        }
        
        var icon: String {
            switch self {
            case .spellings:
                return "plus.circle.fill"
            case .replacements:
                return "arrow.2.squarepath"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Left-aligned header with import/export buttons
                HStack {
                    Text("정확도 향상")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            DictionaryImportExportService.shared.importDictionary(into: modelContext)
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("데이터 가져오기")
                        
                        Button(action: {
                            DictionaryImportExportService.shared.exportDictionary(from: modelContext)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("데이터 내보내기")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Section picker
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        
                        Text("기능 선택")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        Picker("", selection: $selectedSection) {
                            ForEach(DictionarySection.allCases, id: \.self) { section in
                                Text(section.rawValue).tag(section)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    
                    Divider().padding(.leading, 40)
                    
                    // Selected section content
                    selectedSectionContent
                        .padding(.leading, 36)
                        .padding(.top, 12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private var selectedSectionContent: some View {
        switch selectedSection {
        case .spellings:
            VocabularyView(whisperPrompt: whisperPrompt)
        case .replacements:
            WordReplacementView()
        }
    }
}
