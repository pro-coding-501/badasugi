import SwiftUI

struct AudioInputSettingsView: View {
    @ObservedObject var audioDeviceManager = AudioDeviceManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAdvancedExpanded = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Left-aligned header
                Text("마이크")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Main content
                VStack(spacing: 0) {
                    currentMicrophoneRow
                    
                    Divider().padding(.leading, 40)
                    
                    advancedSettingsRow
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // Current microphone selection row
    private var currentMicrophoneRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text("현재 마이크")
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            if audioDeviceManager.availableDevices.isEmpty {
                Text("연결된 마이크 없음")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                Menu {
                    ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                        Button(action: {
                            audioDeviceManager.selectInputMode(.custom)
                            audioDeviceManager.selectDevice(id: device.id)
                        }) {
                            HStack {
                                Text(device.name)
                                if audioDeviceManager.selectedDeviceID == device.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(currentDeviceName)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                .frame(maxWidth: 200)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
    
    private var currentDeviceName: String {
        if let selectedID = audioDeviceManager.selectedDeviceID,
           let device = audioDeviceManager.availableDevices.first(where: { $0.id == selectedID }) {
            return device.name
        }
        let currentID = audioDeviceManager.getCurrentDevice()
        if let device = audioDeviceManager.availableDevices.first(where: { $0.id == currentID }) {
            return device.name
        }
        return "시스템 기본"
    }
    
    // Advanced settings row with disclosure
    private var advancedSettingsRow: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAdvancedExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text("고급 설정")
                        .font(.system(size: 13, weight: .medium))
                    
                    Spacer()
                    
                    Image(systemName: isAdvancedExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isAdvancedExpanded {
                VStack(spacing: 16) {
                    Divider().padding(.leading, 40)
                    
                    inputModeSection
                    
                    if audioDeviceManager.inputMode == .custom {
                        customDeviceSection
                    } else if audioDeviceManager.inputMode == .prioritized {
                        prioritizedDevicesSection
                    }
                }
                .padding(.leading, 36)
                .padding(.bottom, 12)
            }
        }
    }
    
    private var inputModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("입력 모드")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Picker("", selection: Binding(
                get: { audioDeviceManager.inputMode },
                set: { audioDeviceManager.selectInputMode($0) }
            )) {
                Text("직접 선택").tag(AudioInputMode.custom)
                Text("우선순위").tag(AudioInputMode.prioritized)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)
        }
    }
    
    private var customDeviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("장치 목록")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { audioDeviceManager.loadAvailableDevices() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("새로고침")
            }
            
            VStack(spacing: 0) {
                ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                    DeviceRow(
                        name: device.name,
                        isSelected: audioDeviceManager.selectedDeviceID == device.id,
                        isActive: audioDeviceManager.getCurrentDevice() == device.id
                    ) {
                        audioDeviceManager.selectDevice(id: device.id)
                    }
                    
                    if device.id != audioDeviceManager.availableDevices.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
    
    private var prioritizedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if audioDeviceManager.availableDevices.isEmpty {
                HStack {
                    Image(systemName: "mic.slash")
                        .foregroundColor(.secondary)
                    Text("연결된 마이크 없음")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            } else {
                prioritizedDevicesContent
                availableDevicesContent
            }
        }
    }
    
    private var prioritizedDevicesContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("우선순위 장치")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            if audioDeviceManager.prioritizedDevices.isEmpty {
                Text("우선순위 장치 없음")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(audioDeviceManager.prioritizedDevices.sorted(by: { $0.priority < $1.priority })) { device in
                        prioritizedDeviceRow(for: device)
                        
                        if device.id != audioDeviceManager.prioritizedDevices.sorted(by: { $0.priority < $1.priority }).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private func prioritizedDeviceRow(for prioritizedDevice: PrioritizedDevice) -> some View {
        let device = audioDeviceManager.availableDevices.first(where: { $0.uid == prioritizedDevice.id })
        let isActive = device.map { audioDeviceManager.getCurrentDevice() == $0.id } ?? false
        
        return HStack(spacing: 8) {
            Text("\(prioritizedDevice.priority + 1)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Text(prioritizedDevice.name)
                .font(.system(size: 12))
                .foregroundColor(device != nil ? .primary : .secondary)
            
            Spacer()
            
            if isActive {
                Text("활성")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 4) {
                Button(action: { moveDeviceUp(prioritizedDevice) }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10))
                        .foregroundColor(prioritizedDevice.priority > 0 ? .accentColor : .secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .disabled(prioritizedDevice.priority <= 0)
                
                Button(action: { moveDeviceDown(prioritizedDevice) }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(prioritizedDevice.priority < audioDeviceManager.prioritizedDevices.count - 1 ? .accentColor : .secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .disabled(prioritizedDevice.priority >= audioDeviceManager.prioritizedDevices.count - 1)
                
                Button(action: { audioDeviceManager.removePrioritizedDevice(id: prioritizedDevice.id) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var availableDevicesContent: some View {
        let unprioritizedDevices = audioDeviceManager.availableDevices.filter { device in
            !audioDeviceManager.prioritizedDevices.contains { $0.id == device.uid }
        }
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("사용 가능한 장치")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            if unprioritizedDevices.isEmpty {
                Text("추가 장치 없음")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(unprioritizedDevices, id: \.id) { device in
                        HStack {
                            Text(device.name)
                                .font(.system(size: 12))
                            
                            Spacer()
                            
                            if audioDeviceManager.getCurrentDevice() == device.id {
                                Text("활성")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: { audioDeviceManager.addPrioritizedDevice(uid: device.uid, name: device.name) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                        
                        if device.id != unprioritizedDevices.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private func moveDeviceUp(_ device: PrioritizedDevice) {
        guard device.priority > 0,
              let currentIndex = audioDeviceManager.prioritizedDevices.firstIndex(where: { $0.id == device.id })
        else { return }
        
        var devices = audioDeviceManager.prioritizedDevices
        devices.swapAt(currentIndex, currentIndex - 1)
        updatePriorities(devices)
    }
    
    private func moveDeviceDown(_ device: PrioritizedDevice) {
        guard device.priority < audioDeviceManager.prioritizedDevices.count - 1,
              let currentIndex = audioDeviceManager.prioritizedDevices.firstIndex(where: { $0.id == device.id })
        else { return }
        
        var devices = audioDeviceManager.prioritizedDevices
        devices.swapAt(currentIndex, currentIndex + 1)
        updatePriorities(devices)
    }
    
    private func updatePriorities(_ devices: [PrioritizedDevice]) {
        let updatedDevices = devices.enumerated().map { index, device in
            PrioritizedDevice(id: device.id, name: device.name, priority: index)
        }
        audioDeviceManager.updatePriorities(devices: updatedDevices)
    }
}

// Simple device row for custom selection
struct DeviceRow: View {
    let name: String
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isActive {
                    Text("활성")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
