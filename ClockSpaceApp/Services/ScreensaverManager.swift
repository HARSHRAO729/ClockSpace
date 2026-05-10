//
//  ScreensaverManager.swift
//  ClockSpace
//
//  Sprint 2 — Refactored from 823-line God Object into a thin orchestrator.
//  Delegates to:
//    • FileSystemService  — directory ops, file copy/remove
//    • CompilerService     — swiftc compilation, codesigning, plist, thumbnail
//    • KeychainService     — secure storage (used by LicenseManager, not here)
//
//  This class retains ONLY:
//    • @Published UI state (installedIDs, installingIDs, activeID, lastError)
//    • Orchestration logic that coordinates the services
//    • NSWorkspace deep-link handoff for System Settings
//

import Foundation
import AppKit
import Combine

/// Errors specific to screensaver installation operations.
enum ScreensaverInstallError: LocalizedError {
    case fileNotFound(URL)
    case invalidBundle(String)
    case alreadyInstalled(String)
    case permissionDenied(String)
    case copyFailed(String)
    case compilationFailed(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "Source file not found at \(url.path)."
        case .invalidBundle(let name):
            return "\"\(name)\" is not a valid .saver bundle."
        case .alreadyInstalled(let name):
            return "\"\(name)\" is already installed."
        case .permissionDenied(let path):
            return "Permission denied writing to \(path). Check System Settings > Privacy."
        case .copyFailed(let detail):
            return "Failed to copy screensaver: \(detail)"
        case .compilationFailed(let detail):
            return "Compilation failed: \(detail)"
        case .unknown(let detail):
            return "An unexpected error occurred: \(detail)"
        }
    }
}

/// Orchestrates screensaver installation by delegating to focused services.
///
/// **Responsibilities:**
/// - Owns `@Published` UI state (install progress, errors)
/// - Coordinates `FileSystemService` and `CompilerService`
/// - Opens System Settings via `NSWorkspace` deep links
///
/// **Does NOT own:**
/// - File system operations (→ `FileSystemService`)
/// - Compilation pipeline (→ `CompilerService`)
/// - License/security storage (→ `KeychainService`)
@MainActor
final class ScreensaverManager: ObservableObject {
    
    // MARK: - Published State
    
    /// Set of screensaver IDs that are currently installed on this Mac.
    @Published var installedIDs: Set<UUID> = []
    
    /// Set of screensaver IDs currently being installed (for progress UI).
    @Published var installingIDs: Set<UUID> = []
    
    /// The ID of the currently active screensaver.
    @Published var activeID: UUID?
    
    /// Last installation error, if any.
    @Published var lastError: ScreensaverInstallError?
    
    /// Tracks if we have write access to ~/Library/Screen Savers/
    @Published var hasPermission: Bool = true
    
    /// Success message for toast notifications
    @Published var successMessage: String? = nil
    
    // MARK: - Services
    
    private let fileSystem = FileSystemService.shared
    private let installer = InstallerService.shared
    
    // MARK: - Singleton
    
    static let shared = ScreensaverManager()
    
    private init() {
        loadPersistedIDs()
        fileSystem.cleanUpLegacySavers() // Remove UUID-named remnants from previous bugs
        checkPermission()
    }
    
    func checkPermission() {
        hasPermission = fileSystem.canWrite
    }
    
    // MARK: - Convenience Accessors (backward-compatible)
    
    /// The user's Screen Savers directory: ~/Library/Screen Savers/
    var screenSaversDirectory: URL { fileSystem.screenSaversDirectory }
    
    /// Pre-flight check: can the app write to ~/Library/Screen Savers/?
    var canWriteToScreenSaversDirectory: Bool { fileSystem.canWrite }
    
    /// Ensure the Screen Savers directory exists.
    func ensureScreenSaversDirectory() throws { try fileSystem.ensureDirectory() }
    
    // MARK: - Public API: Install
    
    /// Install a .saver bundle from a source URL into ~/Library/Screen Savers/.
    ///
    /// Delegates entirely to `FileSystemService.copyToScreenSavers(from:)`.
    @discardableResult
    func installScreensaver(from source: URL) throws -> URL {
        try fileSystem.copyToScreenSavers(from: source)
    }
    
    /// Install a marketplace screensaver.
    ///
    /// For `local://` savers: resolves from the app bundle and copies.
    /// For remote/template savers: compiles from template, then installs.
    func installFromMarketplace(_ screensaver: Screensaver) async {
        let id = screensaver.id
        
        // Lightweight management: remove previous ClockSpace savers
        clearAllInstalled()
        
        // Drive progress UI
        installingIDs.insert(id)
        lastError = nil
        
        do {
            // Pre-flight: writable directory
            try fileSystem.preflight()
            
            // Delegate installation strategy to InstallerService
            let url = try await installer.install(screensaver)
            
            // Persist filename for future removal (so only ONE exists)
            UserDefaults.standard.set(url.lastPathComponent, forKey: "cs_last_installed_file")
            
            // Mark as installed
            installedIDs.insert(id)
            persistInstalledIDs()
            
            // Trigger success feedback
            successMessage = "Success! Please activate \(screensaver.name) in System Settings."
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if self.successMessage?.contains(screensaver.name) == true {
                    self.successMessage = nil
                }
            }
            
        } catch let error as ScreensaverInstallError {
            lastError = error
            AlertProvider.shared.showAlert(title: "Installation Failed", message: error.localizedDescription)
        } catch {
            lastError = .unknown(error.localizedDescription)
            AlertProvider.shared.showError(error)
        }
        
        installingIDs.remove(id)
    }
    
    // MARK: - Public API: Uninstall
    
    /// Uninstall a screensaver by removing it from ~/Library/Screen Savers/.
    func uninstallScreensaver(_ screensaver: Screensaver) {
        let fileName = screensaver.name
            .replacingOccurrences(of: " ", with: "-")
            .lowercased() + ".saver"
        
        fileSystem.removeSaver(named: fileName)
        installedIDs.remove(screensaver.id)
        persistInstalledIDs()
    }
    
    /// Remove previous ClockSpace-related savers from the system.
    func clearAllInstalled() {
        // 1. Remove by filename tracked in UserDefaults
        if let lastFile = UserDefaults.standard.string(forKey: "cs_last_installed_file") {
            fileSystem.removeSaver(named: lastFile)
        }
        
        // 2. Aggressive cleanup of legacy UUIDs
        fileSystem.cleanUpLegacySavers()
        
        installedIDs.removeAll()
        activeID = nil
        persistInstalledIDs()
        
        UserDefaults.standard.removeObject(forKey: "cs_last_installed_file")
    }
    
    // MARK: - Public API: State Queries
    
    /// Check if a specific screensaver is installed.
    func isInstalled(_ screensaver: Screensaver) -> Bool {
        installedIDs.contains(screensaver.id)
    }
    
    /// Check if a specific screensaver is currently being installed.
    func isInstalling(_ screensaver: Screensaver) -> Bool {
        installingIDs.contains(screensaver.id)
    }
    
    /// Uninstall a screensaver.
    func uninstall(_ screensaver: Screensaver) {
        // If it was the last installed file, we know its name
        if let lastFile = UserDefaults.standard.string(forKey: "cs_last_installed_file") {
            try? fileSystem.uninstall(fileName: lastFile)
            UserDefaults.standard.removeObject(forKey: "cs_last_installed_file")
        }
        
        installedIDs.remove(screensaver.id)
        if activeID == screensaver.id { activeID = nil }
        persistInstalledIDs()
    }
    
    /// Trigger the manual folder permission request.
    func requestPermission() {
        fileSystem.requestManualFolderAccess()
    }
    
    // MARK: - System Settings Handoff
    
    /// Open System Settings to the Screen Saver pane so the user can select
    /// their newly installed screensaver.
    ///
    /// Uses NSWorkspace deep links (sandbox-compatible, reliable on Sonoma/Sequoia).
    @discardableResult
    func applyScreensaver(name: String, path: String) -> Bool {
        guard FileManager.default.fileExists(atPath: path) else {
            lastError = ScreensaverInstallError.fileNotFound(URL(fileURLWithPath: path))
            return false
        }
        
        let deepLinkURLs = [
            "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension",
            "x-apple.systempreferences:com.apple.WallpaperSettings"
        ]
        
        for urlString in deepLinkURLs {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) {
                return true
            }
        }
        
        // Ultimate fallback — open System Settings top level
        if let url = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(url)
        }
        return true
    }
    
    // MARK: - Persistence
    
    /// Load persisted installed IDs from UserDefaults on launch.
    private func loadPersistedIDs() {
        if let data = UserDefaults.standard.data(forKey: CSConstants.DefaultsKey.installedSaverIDs),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            installedIDs = ids
        }
    }
    
    /// Persist the set of installed IDs to UserDefaults.
    private func persistInstalledIDs() {
        if let data = try? JSONEncoder().encode(installedIDs) {
            UserDefaults.standard.set(data, forKey: CSConstants.DefaultsKey.installedSaverIDs)
        }
    }
}
