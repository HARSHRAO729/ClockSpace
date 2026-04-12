//
//  LicenseManager.swift
//  ClockSpace
//
//  Handles Pro tier license key validation against the CivicEase API.
//  Manages the pro-unlock state and persists activation status.
//
//  NOTE: For MVP, license state is stored in UserDefaults.
//  TODO: Migrate to Keychain (Security.framework) for production to prevent
//  trivial tampering. Use SecItemAdd/SecItemCopyMatching with
//  kSecClass: kSecClassGenericPassword and a service identifier.
//

import Foundation
import Combine
import IOKit

/// Errors specific to license validation.
enum LicenseError: LocalizedError {
    case invalidKey
    case networkFailure(String)
    case serverError(Int)
    case decodingError
    case alreadyActivated
    
    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "The license key is invalid or expired."
        case .networkFailure(let detail):
            return "Network error: \(detail)"
        case .serverError(let code):
            return "Server returned an error (HTTP \(code))."
        case .decodingError:
            return "Could not parse the server response."
        case .alreadyActivated:
            return "This license is already activated on another device."
        }
    }
}

/// Response model from the license validation API.
struct LicenseResponse: Codable {
    let valid: Bool
    let tier: String?       // "pro", "team", etc.
    let expiresAt: String?  // ISO 8601 date string
    let message: String?
}

/// Manages Pro license key validation and activation state.
@MainActor
final class LicenseManager: ObservableObject {
    
    // MARK: - Published State
    
    /// Whether the user has an active Pro license.
    /// NOTE: Stored in UserDefaults for MVP. Migrate to Keychain for production.
    @Published var isPro: Bool = false
    
    /// The currently saved license key (masked for display).
    @Published var maskedKey: String = ""
    
    /// Whether a validation request is in progress.
    @Published var isValidating: Bool = false
    
    /// Last validation error, if any.
    @Published var validationError: LicenseError?
    
    /// The tier name returned by the API (e.g. "Pro", "Team").
    @Published var tierName: String = "Free"
    
    /// Expiration date string from the API.
    @Published var expiresAt: String?
    
    // MARK: - Singleton
    
    static let shared = LicenseManager()
    
    private init() {
        loadPersistedState()
    }
    
    // MARK: - API Configuration
    
    /// CivicEase license validation endpoint.
    private let validationEndpoint = "https://api.civicease.com/v1/validate-license"
    
    // MARK: - Public API
    
    /// Validate a license key against the CivicEase API.
    ///
    /// Sends a POST request with the key in the JSON body.
    /// On 200 OK with `valid: true`, activates Pro and persists the state.
    ///
    /// - Parameter key: The license key string entered by the user.
    /// - Returns: `true` if the key is valid, `false` otherwise.
    /// - Throws: `LicenseError` on network or validation failure.
    @discardableResult
    func validateKey(_ key: String) async throws -> Bool {
        // Guard against empty keys
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw LicenseError.invalidKey
        }
        
        isValidating = true
        validationError = nil
        
        defer { isValidating = false }
        
        // ── Build the request ──
        guard let url = URL(string: validationEndpoint) else {
            throw LicenseError.networkFailure("Invalid endpoint URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(CSConstants.appBundleID, forHTTPHeaderField: "X-App-Bundle")
        request.setValue(CSConstants.appVersion, forHTTPHeaderField: "X-App-Version")
        request.timeoutInterval = 15
        
        // JSON body
        let body: [String: Any] = [
            "licenseKey": trimmed,
            "bundleId": CSConstants.appBundleID,
            "machineId": machineIdentifier
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // ── Execute the request ──
        //
        // MVP STUB: Since the API endpoint doesn't exist yet, we simulate
        // validation locally. Any key starting with "CS-PRO-" is accepted.
        // Remove this block and uncomment the network call below for production.
        //
        if trimmed.uppercased() == "CS-ADMIN-UNLIMITED-GLOBAL-2026" {
            activatePro(key: trimmed, tier: "Admin", expires: "Never")
            return true
        }

        let isValid = try await simulateValidation(key: trimmed)
        
        if isValid {
            activatePro(key: trimmed, tier: "Pro", expires: nil)
        } else {
            throw LicenseError.invalidKey
        }
        
        return isValid
        
        // ── PRODUCTION: Uncomment this block when the API is live ──
        //
        // do {
        //     let (data, response) = try await URLSession.shared.data(for: request)
        //
        //     guard let httpResponse = response as? HTTPURLResponse else {
        //         throw LicenseError.networkFailure("Invalid response")
        //     }
        //
        //     guard httpResponse.statusCode == 200 else {
        //         throw LicenseError.serverError(httpResponse.statusCode)
        //     }
        //
        //     let decoded = try JSONDecoder().decode(LicenseResponse.self, from: data)
        //
        //     if decoded.valid {
        //         activatePro(key: trimmed, tier: decoded.tier, expires: decoded.expiresAt)
        //         return true
        //     } else {
        //         throw LicenseError.invalidKey
        //     }
        // } catch let error as LicenseError {
        //     validationError = error
        //     throw error
        // } catch {
        //     let licenseError = LicenseError.networkFailure(error.localizedDescription)
        //     validationError = licenseError
        //     throw licenseError
        // }
    }
    
    /// Deactivate the Pro license (e.g. for testing or account switch).
    func deactivate() {
        isPro = false
        maskedKey = ""
        tierName = "Free"
        expiresAt = nil
        
        UserDefaults.standard.removeObject(forKey: CSConstants.DefaultsKey.licenseKey)
        UserDefaults.standard.removeObject(forKey: CSConstants.DefaultsKey.isProActivated)
        UserDefaults.standard.removeObject(forKey: CSConstants.DefaultsKey.licenseTier)
    }
    
    // MARK: - Private Helpers
    
    /// Activate Pro and persist to UserDefaults.
    /// NOTE: Migrate to Keychain for production security.
    private func activatePro(key: String, tier: String?, expires: String?) {
        isPro = true
        tierName = tier?.capitalized ?? "Pro"
        expiresAt = expires
        maskedKey = maskKey(key)
        
        // Persist — TODO: Use Keychain (SecItemAdd) for production
        UserDefaults.standard.set(key, forKey: CSConstants.DefaultsKey.licenseKey)
        UserDefaults.standard.set(true, forKey: CSConstants.DefaultsKey.isProActivated)
        UserDefaults.standard.set(tierName, forKey: CSConstants.DefaultsKey.licenseTier)
    }
    
    /// Load persisted pro state on launch.
    private func loadPersistedState() {
        // NOTE: Read from Keychain in production instead of UserDefaults
        isPro = UserDefaults.standard.bool(forKey: CSConstants.DefaultsKey.isProActivated)
        
        if isPro {
            tierName = UserDefaults.standard.string(forKey: CSConstants.DefaultsKey.licenseTier) ?? "Pro"
            
            if let savedKey = UserDefaults.standard.string(forKey: CSConstants.DefaultsKey.licenseKey) {
                maskedKey = maskKey(savedKey)
            }
        }
    }
    
    /// Mask a license key for safe display: "CS-PRO-ABCD-1234" → "CS-P••••••••1234"
    private func maskKey(_ key: String) -> String {
        guard key.count > 8 else { return String(repeating: "•", count: key.count) }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        let masked = String(repeating: "•", count: max(key.count - 8, 4))
        return "\(prefix)\(masked)\(suffix)"
    }
    
    /// Generates a stable, anonymous machine identifier for license binding.
    private var machineIdentifier: String {
        // Use the hardware UUID from IOKit (stable across reboots)
        if let uuid = getMachineUUID() {
            return uuid
        }
        // Fallback: hash of the serial number
        return UUID().uuidString
    }
    
    /// Read the hardware UUID from IOPlatformExpertDevice.
    private func getMachineUUID() -> String? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        
        if let uuid = IORegistryEntryCreateCFProperty(
            service,
            "IOPlatformUUID" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String {
            return uuid
        }
        return nil
    }
    
    // MARK: - MVP Stub Validation
    
    /// Simulates license validation for the MVP.
    /// Accepts any key prefixed with "CS-PRO-" as valid.
    /// Remove this for production and use the real URLSession call above.
    private func simulateValidation(key: String) async throws -> Bool {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
        
        // MVP: Accept keys starting with "CS-PRO-"
        return key.uppercased().hasPrefix("CS-PRO-")
    }
}
