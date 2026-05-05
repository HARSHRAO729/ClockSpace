//
//  KeychainService.swift
//  ClockSpace
//
//  Secure storage wrapper using macOS Keychain (Security.framework).
//  Replaces UserDefaults for sensitive data like license keys.
//
//  Sprint 2 deliverable — addresses the security audit finding that
//  license keys were stored in plaintext UserDefaults.
//

import Foundation
import Security

/// Thin wrapper over the macOS Keychain for storing/retrieving string values.
///
/// Usage:
/// ```swift
/// try KeychainService.shared.save("my-secret", forKey: "licenseKey")
/// let key = KeychainService.shared.load(forKey: "licenseKey")
/// ```
struct KeychainService {
    
    // MARK: - Singleton
    
    static let shared = KeychainService()
    private init() {}
    
    /// The Keychain service identifier. Groups all ClockSpace items together.
    private let service = CSConstants.appBundleID
    
    // MARK: - Public API
    
    /// Save a string value to the Keychain.
    ///
    /// - Parameters:
    ///   - value: The string to store.
    ///   - key: A unique key identifier (e.g. "licenseKey").
    /// - Throws: `KeychainError` if the operation fails.
    func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        // Delete any existing item first (SecItemUpdate is less reliable)
        delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  key,
            kSecValueData as String:    data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    /// Load a string value from the Keychain.
    ///
    /// - Parameter key: The key identifier.
    /// - Returns: The stored string, or `nil` if not found.
    func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  key,
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    /// Delete a value from the Keychain.
    ///
    /// - Parameter key: The key identifier.
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Check whether a value exists for a given key without loading it.
    func exists(forKey key: String) -> Bool {
        load(forKey: key) != nil
    }
    
    /// Delete all ClockSpace items from the Keychain.
    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Error Type

enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode the value for Keychain storage."
        case .saveFailed(let status):
            return "Keychain save failed with status \(status)."
        case .loadFailed(let status):
            return "Keychain load failed with status \(status)."
        }
    }
}
