import SwiftUI

struct TrialExpiredView: View {
    @ObservedObject var licenseViewModel: LicenseViewModel
    @State private var showLicenseInput = false
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon and Title
            VStack(spacing: 24) {
                // Lock Icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.red.opacity(0.2),
                                    Color.red.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 16)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.bottom, 12)
                
                // Title
                VStack(spacing: 12) {
                    Text("체험 기간이 만료되었습니다")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("받아쓰기의 모든 기능을 계속 사용하려면\n라이선스를 구매해주세요")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.bottom, 32)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Primary: Activate License
                    Button(action: {
                        showLicenseInput = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 16))
                            Text("라이선스 키 입력")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: 320)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    
                    // Secondary: Buy License (Disabled - purchase page not ready)
                    Button(action: {
                        if let url = URL(string: "https://www.badasugi.com") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 16))
                            Text("평생 라이선스 구매")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .frame(maxWidth: 320)
                        .padding(.vertical, 14)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Bottom Info
            VStack(spacing: 8) {
                Divider()
                    .padding(.horizontal, 40)
                
                HStack(spacing: 16) {
                    // Support
                    Button(action: {
                        EmailSupport.openSupportEmail()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "questionmark.circle")
                            Text("문의하기")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    // License Portal (Disabled - not using Polar)
                    /*
                    Button(action: {
                        EmailSupport.openSupportEmail()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope")
                            Text("문의하기")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    */
                }
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showLicenseInput) {
            LicenseInputSheet(licenseViewModel: licenseViewModel)
        }
    }
}





