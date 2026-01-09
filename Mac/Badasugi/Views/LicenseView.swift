import SwiftUI

struct LicenseView: View {
    @StateObject private var licenseViewModel = LicenseViewModel()
    
    var body: some View {
        VStack(spacing: 15) {
            Text("License Management")
                .font(.headline)
            
            if case .licensed = licenseViewModel.licenseState {
                VStack(spacing: 10) {
                    Text("Premium Features Activated")
                        .foregroundColor(.green)
                    
                    Button(role: .destructive, action: {
                        licenseViewModel.removeLicense()
                    }) {
                        Text("Remove License")
                    }
                }
            } else {
                TextField("Enter License Key", text: $licenseViewModel.licenseKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 300)
                
                Button(action: {
                    Task {
                        await licenseViewModel.validateLicense()
                    }
                }) {
                    if licenseViewModel.isValidating {
                        ProgressView()
                    } else {
                        Text("Activate License")
                    }
                }
                .disabled(licenseViewModel.isValidating)
            }
            
            if let message = licenseViewModel.validationMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message)
                        .foregroundColor(licenseViewModel.licenseState == .licensed ? .green : .red)
                        .font(.caption)
                    
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
        .padding()
    }
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseView()
    }
} 