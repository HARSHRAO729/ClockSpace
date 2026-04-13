//
//  Constants.swift
//  ClockSpace
//
//  Shared constants used across both the App and Screen Saver targets.
//

import Foundation

/// App-wide constants shared between the Dashboard and Screen Saver targets.
enum CSConstants {
    
    // MARK: - App Identity
    
    static let appName = "ClockSpace"
    static let appVersion = "0.25"
    static let buildNumber = "1"
    
    // MARK: - Bundle Identifiers
    
    static let appBundleID = "CivicEase.ClockSpace"
    static let saverBundleID = "com.clockspace.saver"
    
    // MARK: - API Configuration
    
    /// Base URL for the ClockSpace marketplace API.
    /// Currently points to a local stub; swap for production endpoint when ready.
    static var apiBaseURL: String {
        Secrets.supabaseURL ?? "https://api.clockspace.dev/v1"
    }
    
    // MARK: - API Endpoints
    
    enum Endpoint {
        static let screensavers = "/screensavers"
        static let search = "/screensavers/search"
        static let download = "/screensavers/download"
        static let featured = "/screensavers/featured"
        static let categories = "/categories"
    }

    // MARK: - Secrets
    
    /// Securely managed API keys and secrets.
    /// These are loaded from Secrets.xcconfig via Info.plist.
    enum Secrets {
        static var licenseAPIKey: String? {
            Bundle.main.object(forInfoDictionaryKey: "LICENSE_API_KEY") as? String
        }
        
        static var supabaseURL: String? {
            Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        }
    }
    
    // MARK: - Defaults Keys
    
    enum DefaultsKey {
        static let selectedCategory = "cs_selectedCategory"
        static let lastSyncDate = "cs_lastSyncDate"
        static let installedSaverIDs = "cs_installedSaverIDs"
        
        // License — TODO: Migrate to Keychain for production
        static let licenseKey = "cs_licenseKey"
        static let isProActivated = "cs_isProActivated"
        static let licenseTier = "cs_licenseTier"
    }
    
    // MARK: - Layout
    
    enum Layout {
        static let windowDefaultWidth: CGFloat = 1100
        static let windowDefaultHeight: CGFloat = 720
        static let windowMinWidth: CGFloat = 860
        static let windowMinHeight: CGFloat = 560
        static let windowMaxWidth: CGFloat = 1100
        static let windowMaxHeight: CGFloat = 720
        static let sidebarWidth: CGFloat = 220
    }
}
