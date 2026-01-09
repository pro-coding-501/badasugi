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
            ScrollView {
                VStack(spacing: 24) {
                    // 기본 설정
                    SettingsSection(
                        icon: "sparkles",
                        title: "기본 설정",
                        subtitle: "텍스트 다듬기 기능 활성화"
                    ) {
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.secondary.opacity(0.1))
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text("문장 다듬기 사용")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        InfoTip(
                                            title: "문장 다듬기",
                                            message: "받아쓴 텍스트를 자동으로 다듬습니다. 문법 수정, 문장 정리, 요약 등 다양한 스타일로 변환할 수 있습니다.",
                                            learnMoreURL: "https://www.badasugi.com"
                                        )
                                    }
                                    Text("받아쓴 텍스트를 자동으로 다듬습니다")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $enhancementService.isEnhancementEnabled)
                                    .toggleStyle(.switch)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(10)
                    }
                    
                    // 다듬기 스타일
                    SettingsSection(
                        icon: "paintbrush.fill",
                        title: "다듬기 스타일",
                        subtitle: "텍스트를 다듬는 스타일을 선택하세요"
                    ) {
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
                        .opacity(enhancementService.isEnhancementEnabled ? 1.0 : 0.6)
                    }
                    
                    // 컨텍스트 설정
                    SettingsSection(
                        icon: "contextualmenu.and.cursorarrow",
                        title: "컨텍스트 설정",
                        subtitle: "다듬기 정확도를 높이는 컨텍스트 사용"
                    ) {
                        VStack(spacing: 0) {
                            // 클립보드 컨텍스트
                            HStack(spacing: 12) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.secondary.opacity(0.1))
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("클립보드 컨텍스트")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("클립보드의 텍스트를 참고하여 더 정확하게 다듬습니다")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $enhancementService.useClipboardContext)
                                    .toggleStyle(.switch)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // 화면 컨텍스트
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.dashed.and.paperclip")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.secondary.opacity(0.1))
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("화면 컨텍스트")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("화면에 표시된 내용을 참고하여 더 정확하게 다듬습니다")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $enhancementService.useScreenCaptureContext)
                                    .toggleStyle(.switch)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(10)
                        .opacity(enhancementService.isEnhancementEnabled ? 1.0 : 0.6)
                    }
                    
                    // 고급 설정
                    SettingsSection(
                        icon: "gearshape.fill",
                        title: "고급 설정",
                        subtitle: "연결 관리 및 단축키 설정"
                    ) {
                        VStack(spacing: 0) {
                            // 연결 관리
                            DisclosureGroup(isExpanded: $isConnectionExpanded) {
                                APIKeyManagementView()
                                    .padding(.vertical, 8)
                                    .padding(.leading, 52)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "link")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 28, height: 28)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.secondary.opacity(0.1))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("연결 관리")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("API 키 및 연결 상태 관리")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    if enhancementService.isEnhancementEnabled {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // 단축키
                            NavigationLink {
                                EnhancementShortcutsView()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "keyboard")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 28, height: 28)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.secondary.opacity(0.1))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("단축키")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("텍스트 다듬기 관련 단축키 설정")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(10)
                        .opacity(enhancementService.isEnhancementEnabled ? 1.0 : 0.6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
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
                            .padding(.leading, 52)
                    }
                }
            }
            
            // Add New Style button at the bottom
            if !enhancementService.customPrompts.isEmpty {
                Divider()
                    .padding(.leading, 52)
            }
            
            Button(action: onAddNew) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor.opacity(0.1))
                        )
                    
                    Text("새 스타일 추가...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
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
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: prompt.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    )
                
                // Title and Description
                VStack(alignment: .leading, spacing: 2) {
                    Text(prompt.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let description = prompt.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHovering ? Color.primary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
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
