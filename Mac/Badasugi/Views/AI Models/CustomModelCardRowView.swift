import SwiftUI
import AppKit

// MARK: - Custom Model Card Row View
struct CustomModelCardRowView: View {
    let model: CustomCloudModel
    @ObservedObject var whisperState: WhisperState
    let isCurrent: Bool
    let onDelete: () -> Void
    let onEdit: (CustomCloudModel) -> Void
    let onSelect: () -> Void
    
    var body: some View {
        CustomModelCardView(
            model: model,
            isCurrent: isCurrent,
            setDefaultAction: onSelect,
            deleteAction: onDelete,
            editAction: onEdit
        )
    }
}

// MARK: - Custom Model Card View
struct CustomModelCardView: View {
    let model: CustomCloudModel
    let isCurrent: Bool
    var setDefaultAction: () -> Void
    var deleteAction: () -> Void
    var editAction: (CustomCloudModel) -> Void
    
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
        }
        .background(CardBackground(isSelected: isCurrent, useAccentGradientWhenSelected: isCurrent))
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
        Group {
            if isCurrent {
                Text("기본")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundColor(.white)
            } else {
                Text("사용자 지정")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                    .foregroundColor(Color.orange)
            }
        }
    }
    
    private var metadataSection: some View {
        HStack(spacing: 12) {
            // Provider
            Label("사용자 지정 제공업체", systemImage: "cloud")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabelColor))
                .lineLimit(1)
            
            // Language
            Label(model.language, systemImage: "globe")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabelColor))
                .lineLimit(1)
            
            // OpenAI Compatible
            Label("OpenAI 호환", systemImage: "checkmark.seal")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabelColor))
                .lineLimit(1)
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
            } else {
                Button(action: setDefaultAction) {
                    Text("기본으로 설정")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Menu {
                Button {
                    editAction(model)
                } label: {
                    Label("모델 편집", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    deleteAction()
                } label: {
                    Label("모델 삭제", systemImage: "trash")
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
