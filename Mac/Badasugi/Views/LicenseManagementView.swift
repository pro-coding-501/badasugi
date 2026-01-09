import SwiftUI

struct LicenseManagementView: View {
    @StateObject private var licenseViewModel = LicenseViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showLicenseInput = false
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Premium Branding Area with Logo and Glow
                brandingSection
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Native List Content
                listContent
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showLicenseInput) {
            LicenseInputSheet(licenseViewModel: licenseViewModel)
        }
    }
    
    // MARK: - Branding Section (Logo + Glow + Status)
    private var brandingSection: some View {
        VStack(spacing: 14) {
            // App Icon with Subtle Glow
            ZStack {
                // Outer glow - more subtle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentColor.opacity(0.2),
                                Color.accentColor.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                // Inner glow - more subtle
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 130, height: 130)
                    .blur(radius: 16)
                
                // App Icon - Using BadasugiLogoMac
                Image("BadasugiLogoMac")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 144, height: 144)
                    .cornerRadius(34)
                    .shadow(color: .accentColor.opacity(0.3), radius: 15)
            }
            
            // Status Text - Large and Premium Style
            statusText
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var statusText: some View {
        switch licenseViewModel.licenseState {
        case .licensed:
            VStack(spacing: 12) {
                // Large title with checkmark
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("받아쓰기 정식 버전")
                        .font(.system(size: 28, weight: .bold))
                }
                
                // Version badge
                Text("v\(appVersion)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            
        case .trial(let daysRemaining):
            VStack(spacing: 12) {
                // Large trial title
                Text("받아쓰기 체험판")
                    .font(.system(size: 28, weight: .bold))
                
                // Days remaining badge
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    
                    Text("\(daysRemaining)일 남음")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.15))
                )
                
                // Version
                Text("v\(appVersion)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
        case .trialExpired:
            VStack(spacing: 12) {
                // Expired title
                Text("받아쓰기 체험판")
                    .font(.system(size: 28, weight: .bold))
                
                // Expired badge
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    
                    Text("체험 기간 만료")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.15))
                )
                
                Text("계속 사용하려면 라이선스를 구매하세요")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Native List Content
    private var listContent: some View {
        VStack(spacing: 0) {
            if case .licensed = licenseViewModel.licenseState {
                activatedListContent
            } else {
                trialListContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Trial Mode List Items
    private var trialListContent: some View {
        VStack(spacing: 0) {
            // Enter License Key
            ListRow(
                icon: "key.fill",
                iconColor: .accentColor,
                title: "라이선스 키 입력",
                subtitle: "이미 구매하셨나요?",
                showChevron: true
            ) {
                showLicenseInput = true
            }
            
            Divider().padding(.leading, 40)
            
            // Buy Lifetime License (Disabled - purchase page not ready)
            ListRow(
                icon: "cart.fill",
                iconColor: .mint,
                title: "홈페이지 방문",
                subtitle: "받아쓰기 공식 웹사이트",
                showExternalLink: true
            ) {
                if let url = URL(string: "https://www.badasugi.com") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Divider().padding(.leading, 40)
            
            // Email Support (Replaced Polar portal)
            ListRow(
                icon: "envelope.fill",
                iconColor: .mint,
                title: "이메일 지원",
                subtitle: "문의 및 지원 요청",
                showExternalLink: false
            ) {
                EmailSupport.openSupportEmail()
            }
        }
    }
    
    // MARK: - Activated Mode List Items
    private var activatedListContent: some View {
        VStack(spacing: 0) {
            // Device Usage
            if licenseViewModel.activationsLimit > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("기기 사용")
                            .font(.system(size: 13, weight: .medium))
                        Text("최대 \(licenseViewModel.activationsLimit)개 기기에서 사용 가능")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("1 / \(licenseViewModel.activationsLimit)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                
                Divider().padding(.leading, 40)
            }
            
            // 이메일 지원
            ListRow(
                icon: "envelope",
                iconColor: .secondary,
                title: "이메일 지원",
                subtitle: nil,
                showChevron: false
            ) {
                EmailSupport.openSupportEmail()
            }
            
            Divider().padding(.leading, 40)
            
            // 이 Mac에서 비활성화
            ListRow(
                icon: "xmark.circle.fill",
                iconColor: .red.opacity(0.8),
                title: "이 Mac에서 비활성화",
                subtitle: "라이선스 슬롯 해제",
                showChevron: false,
                titleColor: .red.opacity(0.8)
            ) {
                licenseViewModel.removeLicense()
            }
        }
    }
}

// MARK: - List Row Component
struct ListRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    var showChevron: Bool = false
    var showExternalLink: Bool = false
    var titleColor: Color = .primary
    let action: () -> Void
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil, showChevron: Bool = false, showExternalLink: Bool = false, titleColor: Color = .primary, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.showExternalLink = showExternalLink
        self.titleColor = titleColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(titleColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                if showExternalLink {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - License Input Sheet
struct LicenseInputSheet: View {
    @ObservedObject var licenseViewModel: LicenseViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("라이선스 키 입력")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Input Field
            VStack(alignment: .leading, spacing: 8) {
                TextField("라이선스 키를 입력하세요", text: $licenseViewModel.licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .textCase(.uppercase)
                
                if let message = licenseViewModel.validationMessage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(licenseViewModel.licenseState == .licensed ? .green : .red)
                        
                        // Show device usage info if available
                        if licenseViewModel.licenseState == .licensed,
                           licenseViewModel.maxDevices > 0 {
                            Text("기기 사용: \(licenseViewModel.activeDevices) / \(licenseViewModel.maxDevices)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Buttons
            HStack {
                Button("취소") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await licenseViewModel.validateLicense()
                        if case .licensed = licenseViewModel.licenseState {
                            dismiss()
                        }
                    }
                }) {
                    if licenseViewModel.isValidating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("활성화")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(licenseViewModel.licenseKey.isEmpty || licenseViewModel.isValidating)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
