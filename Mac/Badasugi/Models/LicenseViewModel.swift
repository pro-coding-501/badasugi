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
    private let polarService = PolarService()
    private let userDefaults = UserDefaults.standard
    // DISABLED: License server not yet deployed in production
    // private let licenseServerURL = "http://localhost:3000/license/activate"
    private let licenseServerURL = "" // Disabled until production server is ready
    
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
        // DISABLED: License server not yet deployed
        validationMessage = "라이선스 활성화 기능은 아직 사용할 수 없습니다. 업데이트를 기다려주세요."
        return
        
        /* Disabled until license server is deployed
        guard !licenseKey.isEmpty else {
            validationMessage = "라이선스 키를 입력해주세요"
            return
        }
        
        isValidating = true
        validationMessage = nil
        
        // 디버깅용: rawBody를 함수 스코프에서 접근 가능하도록 선언
        var rawBody: String = ""
        
        do {
            let deviceId = getDeviceId()
            let deviceName = getDeviceName()
            
            // Prepare request
            guard let url = URL(string: licenseServerURL) else {
                validationMessage = "잘못된 서버 URL입니다"
                isValidating = false
                return
            }
            
            let requestBody = ActivationRequest(
                licenseKey: licenseKey,
                deviceId: deviceId,
                deviceName: deviceName
            )
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            // Make API call
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                validationMessage = "서버 응답을 받을 수 없습니다"
                isValidating = false
                return
            }
            
            // 디버깅: raw response body 변환
            rawBody = String(data: data, encoding: .utf8) ?? "Unable to decode response body"
            let statusCode = httpResponse.statusCode
            let dataCount = data.count
            
            // 디버깅 정보를 validationMessage에 추가
            var debugInfo = "HTTP Status: \(statusCode), Data Count: \(dataCount), Raw Body: \(rawBody)"
            
            // data.count == 0이면 디코딩 시도하지 말고 return
            if dataCount == 0 {
                validationMessage = debugInfo
                isValidating = false
                return
            }
            
            // status code가 200..299가 아니면 디코딩 시도하지 말고 rawBody를 그대로 보여주고 return
            if !(200...299).contains(statusCode) {
                validationMessage = debugInfo
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
            
        } catch let decodingError as DecodingError {
            let rawBodyInfo = rawBody.isEmpty ? "" : ", Raw Body: \(rawBody)"
            validationMessage = "응답 파싱 오류: \(decodingError.localizedDescription)\(rawBodyInfo)"
        } catch let urlError as URLError {
            let rawBodyInfo = rawBody.isEmpty ? "" : ", Raw Body: \(rawBody)"
            if urlError.code == .cannotConnectToHost || urlError.code == .networkConnectionLost {
                validationMessage = "서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.\(rawBodyInfo)"
            } else {
                validationMessage = "네트워크 오류: \(urlError.localizedDescription)\(rawBodyInfo)"
            }
        } catch {
            let rawBodyInfo = rawBody.isEmpty ? "" : ", Raw Body: \(rawBody)"
            validationMessage = "오류 발생: \(error.localizedDescription)\(rawBodyInfo)"
        }
        
        isValidating = false
        */
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
