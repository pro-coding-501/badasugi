import SwiftUI
import UniformTypeIdentifiers

struct EnhancementSettingsView: View {
    @EnvironmentObject private var enhancementService: AIEnhancementService
    @State private var isEditingPrompt = false
    @State private var isConnectionExpanded = false
    @State private var selectedPromptForEdit: CustomPrompt?
    
    private var isPanelOpen: Bool {
        isEditingPrompt || selectedPromptForEdit != nil
    }
    
    private func closePanel() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            isEditingPrompt = false
            selectedPromptForEdit = nil
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Form {
                // Primary: Toggle
                Section {
                    Toggle(isOn: $enhancementService.isEnhancementEnabled) {
                        HStack(spacing: 4) {
                            Text("문장 다듬기 사용")
                            InfoTip(
                                title: "문장 다듬기",
                                message: "받아쓴 텍스트를 자동으로 다듬습니다. 문법 수정, 문장 정리, 요약 등 다양한 스타일로 변환할 수 있습니다.",
                                learnMoreURL: "https://tryvoiceink.com/docs/enhancements-configuring-models"
                            )
                        }
                    }
                    .toggleStyle(.switch)
                } header: {
                    Text("기본 설정")
                }
                
                // Style picker section - Now a vertical list
                Section {
                    PromptSelectionList(
                        selectedPromptId: enhancementService.selectedPromptId,
                        onPromptSelected: { prompt in
                            enhancementService.setActivePrompt(prompt)
                        },
                        onEditPrompt: { prompt in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                selectedPromptForEdit = prompt
                            }
                        },
                        onDeletePrompt: { prompt in
                            enhancementService.deletePrompt(prompt)
                        },
                        onAddNew: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                isEditingPrompt = true
                            }
                        }
                    )
                } header: {
                    Text("다듬기 스타일")
                }
                .opacity(enhancementService.isEnhancementEnabled ? 1.0 : 0.8)
                
                // Context Settings - Standard list items
                Section {
                    Toggle(isOn: $enhancementService.useClipboardContext) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("클립보드 컨텍스트")
                                    .font(.system(size: 13, weight: .medium))
                                Text("클립보드의 텍스트를 참고하여 더 정확하게 다듬습니다")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                    
                    Toggle(isOn: $enhancementService.useScreenCaptureContext) {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.dashed.and.paperclip")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("화면 컨텍스트")
                                    .font(.system(size: 13, weight: .medium))
                                Text("화면에 표시된 내용을 참고하여 더 정확하게 다듬습니다")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                } header: {
                    Text("컨텍스트 설정")
                }
                .opacity(enhancementService.isEnhancementEnabled ? 1.0 : 0.8)
                
                // Connection management - Standard list section
                Section {
                    DisclosureGroup(isExpanded: $isConnectionExpanded) {
                        APIKeyManagementView()
                            .padding(.vertical, 8)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            Text("연결 관리")
                                .font(.system(size: 13, weight: .medium))
                            
                            Spacer()
                            
                            if enhancementService.isEnhancementEnabled {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    
                    // Shortcuts row
                    NavigationLink {
                        EnhancementShortcutsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            Text("단축키")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                } header: {
                    Text("고급 설정")
                }
                .opacity(enhancementService.isEnhancementEnabled ? 1.0 : 0.8)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Color(NSColor.controlBackgroundColor))
            .disabled(isPanelOpen)
            .blur(radius: isPanelOpen ? 2 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.9), value: isPanelOpen)
            
            if isPanelOpen {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closePanel()
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            if isPanelOpen {
                HStack(spacing: 0) {
                    Spacer()
                    
                    Group {
                        if let prompt = selectedPromptForEdit {
                            PromptEditorView(mode: .edit(prompt)) {
                                closePanel()
                            }
                        } else if isEditingPrompt {
                            PromptEditorView(mode: .add) {
                                closePanel()
                            }
                        }
                    }
                    .frame(width: 450)
                    .frame(maxHeight: .infinity)
                    .background(
                        Color(NSColor.windowBackgroundColor)
                    )
                    .overlay(
                        Divider(), alignment: .leading
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, x: -4, y: 0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                .ignoresSafeArea()
                .zIndex(2)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Prompt Selection List (Vertical List Style)
private struct PromptSelectionList: View {
    @EnvironmentObject private var enhancementService: AIEnhancementService
    
    let selectedPromptId: UUID?
    let onPromptSelected: (CustomPrompt) -> Void
    let onEditPrompt: ((CustomPrompt) -> Void)?
    let onDeletePrompt: ((CustomPrompt) -> Void)?
    let onAddNew: () -> Void
    
    @State private var hoveredPromptId: UUID?
    @State private var draggingItem: CustomPrompt?
    
    var body: some View {
        VStack(spacing: 0) {
            if enhancementService.customPrompts.isEmpty {
                Text("사용 가능한 스타일 없음")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(enhancementService.customPrompts.enumerated()), id: \.element.id) { index, prompt in
                    PromptListRow(
                        prompt: prompt,
                        isSelected: selectedPromptId == prompt.id,
                        isHovered: hoveredPromptId == prompt.id,
                        onTap: { onPromptSelected(prompt) },
                        onEdit: { onEditPrompt?(prompt) },
                        onDelete: { onDeletePrompt?(prompt) }
                    )
                    .onHover { isHovered in
                        hoveredPromptId = isHovered ? prompt.id : nil
                    }
                    .opacity(draggingItem?.id == prompt.id ? 0.5 : 1.0)
                    .onDrag {
                        draggingItem = prompt
                        return NSItemProvider(object: prompt.id.uuidString as NSString)
                    }
                    .onDrop(
                        of: [UTType.text],
                        delegate: PromptDropDelegate(
                            item: prompt,
                            prompts: $enhancementService.customPrompts,
                            draggingItem: $draggingItem
                        )
                    )
                    
                    if index < enhancementService.customPrompts.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            
            // Add New Style button at the bottom
            Divider()
                .padding(.leading, 48)
            
            Button(action: onAddNew) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    
                    Text("새 스타일 추가...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Prompt List Row
private struct PromptListRow: View {
    let prompt: CustomPrompt
    let isSelected: Bool
    let isHovered: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: prompt.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 24)
                
                // Title and Description
                VStack(alignment: .leading, spacing: 2) {
                    Text(prompt.title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(.primary)
                    
                    if let description = prompt.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right side: Selection indicator or hover actions
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentColor)
                } else if isHovered {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("편집")
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("편집") { onEdit() }
            if !prompt.isPredefined {
                Divider()
                Button("삭제", role: .destructive) { onDelete() }
            }
        }
        .onTapGesture(count: 2) {
            onEdit()
        }
    }
}

// MARK: - Drop Delegate
private struct PromptDropDelegate: DropDelegate {
    let item: CustomPrompt
    @Binding var prompts: [CustomPrompt]
    @Binding var draggingItem: CustomPrompt?
    
    func dropEntered(info: DropInfo) {
        guard let draggingItem = draggingItem, draggingItem != item else { return }
        guard let fromIndex = prompts.firstIndex(of: draggingItem),
              let toIndex = prompts.firstIndex(of: item) else { return }
        
        if prompts[toIndex].id != draggingItem.id {
            withAnimation(.easeInOut(duration: 0.12)) {
                let from = fromIndex
                let to = toIndex
                prompts.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }
}
