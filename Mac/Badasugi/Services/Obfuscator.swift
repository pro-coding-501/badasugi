import Foundation

/// Simple utility to obfuscate sensitive data stored in UserDefaults
struct Obfuscator {
    
    /// Encodes a string using Base64 with a device-specific salt
    static func encode(_ string: String, salt: String) -> String {
        let salted = salt + string + salt
        let data = Data(salted.utf8)
        return data.base64EncodedString()
    }
    
    /// Decodes a Base64 string using a device-specific salt
    static func decode(_ base64: String, salt: String) -> String? {
        guard let data = Data(base64Encoded: base64),
              let salted = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Remove the salt from both ends
        guard salted.hasPrefix(salt), salted.hasSuffix(salt) else { 
            return nil 
        }
        
        return String(salted.dropFirst(salt.count).dropLast(salt.count))
    }
    
    /// Gets a device-specific identifier to use as salt
    /// Uses only UUID stored in UserDefaults for stability
    static func getDeviceIdentifier() -> String {
        let defaults = UserDefaults.standard
        
        // Return stored UUID if exists
        if let storedId = defaults.string(forKey: "BadasugiDeviceIdentifier") {
            return storedId
        }
        
        // Create and store new UUID
        let newId = UUID().uuidString
        defaults.set(newId, forKey: "BadasugiDeviceIdentifier")
        return newId
    }
}
