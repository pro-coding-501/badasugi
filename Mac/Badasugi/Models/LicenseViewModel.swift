import Foundation
import AppKit

// MARK: - API Response Models
struct ActivationResponse: Codable {
    let success: Bool
    let message: String?
    let activeDevices: Int?
    let maxDevices: Int?
    let licenseKey: String?
    let deviceId: String?
}

struct ActivationRequest: Codable {
    let licenseKey: String
    let deviceId: String
    let deviceName: String
}

@MainActor
class LicenseViewModel: ObservableObject {
    enum LicenseState: Equatable {
        case trial(daysRemaining: Int)
        case trialExpired
        case licensed
    }
    
    @Published private(set) var licenseState: LicenseState = .trial(daysRemaining: 7)  // Default to trial
    @Published var licenseKey: String = ""
    @Published var isValidating = false
    @Published var validationMessage: String?
    @Published private(set) var activationsLimit: Int = 0
    @Published var activeDevices: Int = 0
    @Published var maxDevices: Int = 0
    
    private let trialPeriodDays = 7
    private let userDefaults = UserDefaults.standard
    
    // 자체 라이선스 서버 URL
    // ⚠️ 배포 시 실제 서버 URL로 자동 전환됩니다
    #if DEBUG
    private let licenseServerURL = "http://localhost:3001/api/license"
    #else
    private let licenseServerURL = "https://api.badasugi.com/api/license"
    #endif
    
    init() {
        loadLicenseState()
    }
    
    func startTrial() {
        // Only set trial start date if it hasn't been set before
        if userDefaults.trialStartDate == nil {
            userDefaults.trialStartDate = Date()
            licenseState = .trial(daysRemaining: trialPeriodDays)
            NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
        }
    }
    
    private func loadLicenseState() {
        // Check for existing license key
        if let licenseKey = userDefaults.licenseKey {
            self.licenseKey = licenseKey
            
            // Check if licensed via new system
            if userDefaults.bool(forKey: "isLicensed") {
                licenseState = .licensed
                activationsLimit = userDefaults.activationsLimit
                return
            }
            
            // Legacy check: If we have a license key, trust that it's licensed
            // Skip server validation on startup
            if userDefaults.activationId != nil || !userDefaults.bool(forKey: "BadasugiLicenseRequiresActivation") {
                licenseState = .licensed
                activationsLimit = userDefaults.activationsLimit
                return
            }
        }
        
        // Check if this is first launch
        let hasLaunchedBefore = userDefaults.bool(forKey: "BadasugiHasLaunchedBefore")
        if !hasLaunchedBefore {
            // First launch - start trial automatically
            userDefaults.set(true, forKey: "BadasugiHasLaunchedBefore")
            startTrial()
            return
        }
        
        // Only check trial if not licensed and not first launch
        if let trialStartDate = userDefaults.trialStartDate {
            let daysSinceTrialStart = Calendar.current.dateComponents([.day], from: trialStartDate, to: Date()).day ?? 0
            
            if daysSinceTrialStart >= trialPeriodDays {
                licenseState = .trialExpired
            } else {
                licenseState = .trial(daysRemaining: trialPeriodDays - daysSinceTrialStart)
            }
        } else {
            // No trial has been started yet - start it now
            startTrial()
        }
    }
    
    var canUseApp: Bool {
        switch licenseState {
        case .licensed, .trial:
            return true
        case .trialExpired:
            return false
        }
    }
    
    var isLocked: Bool {
        return !canUseApp
    }
    
    var trialDaysRemaining: Int {
        switch licenseState {
        case .trial(let daysRemaining):
            return daysRemaining
        case .trialExpired:
            return 0
        case .licensed:
            return 0
        }
    }
    
    func openPurchaseLink() {
        // DISABLED: Purchase page not yet available
        // Will be replaced with official Badasugi purchase page
        if let url = URL(string: "https://www.badasugi.com") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Device Info Helpers
    private func getDeviceId() -> String {
        if let existingId = userDefaults.string(forKey: "deviceId") {
            return existingId
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: "deviceId")
        return newId
    }
    
    private func getDeviceName() -> String {
        return Host.current().localizedName ?? "Mac"
    }
    
    // MARK: - License Activation
    func validateLicense() async {
        guard !licenseKey.isEmpty else {
            validationMessage = "라이선스 키를 입력해주세요"
            return
        }
        
        isValidating = true
        validationMessage = nil
        
        do {
            let deviceId = getDeviceId()
            let deviceName = getDeviceName()
            
            // 1단계: 라이선스 키 검증
            guard let validateUrl = URL(string: "\(licenseServerURL)/validate") else {
                validationMessage = "잘못된 서버 URL입니다"
                isValidating = false
                return
            }
            
            var validateRequest = URLRequest(url: validateUrl)
            validateRequest.httpMethod = "POST"
            validateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            validateRequest.httpBody = try JSONEncoder().encode(["licenseKey": licenseKey])
            
            let (validateData, validateResponse) = try await URLSession.shared.data(for: validateRequest)
            
            guard let httpResponse = validateResponse as? HTTPURLResponse else {
                validationMessage = "서버 응답을 받을 수 없습니다"
                isValidating = false
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorResponse = try? JSONDecoder().decode(ActivationResponse.self, from: validateData)
                validationMessage = errorResponse?.message ?? "유효하지 않은 라이선스 키입니다"
                isValidating = false
                return
            }
            
            // 2단계: 디바이스 활성화
            guard let activateUrl = URL(string: "\(licenseServerURL)/activate") else {
                validationMessage = "잘못된 서버 URL입니다"
                isValidating = false
                return
            }
            
            let requestBody = ActivationRequest(
                licenseKey: licenseKey,
                deviceId: deviceId,
                deviceName: deviceName
            )
            
            var request = URLRequest(url: activateUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            // Make API call
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let activateHttpResponse = response as? HTTPURLResponse else {
                validationMessage = "서버 응답을 받을 수 없습니다"
                isValidating = false
                return
            }
            
            if !(200...299).contains(activateHttpResponse.statusCode) {
                let errorResponse = try? JSONDecoder().decode(ActivationResponse.self, from: data)
                validationMessage = errorResponse?.message ?? "라이선스 활성화에 실패했습니다"
                isValidating = false
                return
            }
            
            // Parse response
            let activationResponse = try JSONDecoder().decode(ActivationResponse.self, from: data)
            
            if activationResponse.success {
                // Success: Save license info
                userDefaults.licenseKey = licenseKey
                userDefaults.set(true, forKey: "isLicensed")
                
                // Update activation limits
                if let activeDevices = activationResponse.activeDevices {
                    self.activeDevices = activeDevices
                }
                if let maxDevices = activationResponse.maxDevices {
                    self.maxDevices = maxDevices
                    self.activationsLimit = maxDevices
                    userDefaults.activationsLimit = maxDevices
                }
                
                // Update license state
                licenseState = .licensed
                
                // Build success message with device info
                var message = activationResponse.message ?? "라이선스가 성공적으로 활성화되었습니다"
                if let activeDevices = activationResponse.activeDevices,
                   let maxDevices = activationResponse.maxDevices {
                    message += "\n기기 사용: \(activeDevices) / \(maxDevices)"
                }
                validationMessage = message
                
                NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
            } else {
                // Failure: Show error message
                validationMessage = activationResponse.message ?? "라이선스 활성화에 실패했습니다"
            }
            
        } catch let urlError as URLError {
            if urlError.code == .cannotConnectToHost || urlError.code == .networkConnectionLost {
                validationMessage = "서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요."
            } else {
                validationMessage = "네트워크 오류: \(urlError.localizedDescription)"
            }
        } catch {
            validationMessage = "오류 발생: \(error.localizedDescription)"
        }
        
        isValidating = false
    }
    
    func removeLicense() {
        // Remove both license key and trial data
        userDefaults.licenseKey = nil
        userDefaults.activationId = nil
        userDefaults.set(false, forKey: "BadasugiLicenseRequiresActivation")
        userDefaults.set(false, forKey: "isLicensed")
        userDefaults.trialStartDate = nil
        userDefaults.set(false, forKey: "BadasugiHasLaunchedBefore")  // Allow trial to restart
        
        userDefaults.activationsLimit = 0
        
        licenseState = .trial(daysRemaining: trialPeriodDays)  // Reset to trial state
        licenseKey = ""
        validationMessage = nil
        activationsLimit = 0
        activeDevices = 0
        maxDevices = 0
        NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
        loadLicenseState()
    }
}


// Add UserDefaults extensions for storing activation ID
extension UserDefaults {
    var activationId: String? {
        get { string(forKey: "BadasugiActivationId") }
        set { set(newValue, forKey: "BadasugiActivationId") }
    }
    
    var activationsLimit: Int {
        get { integer(forKey: "BadasugiActivationsLimit") }
        set { set(newValue, forKey: "BadasugiActivationsLimit") }
    }
}
