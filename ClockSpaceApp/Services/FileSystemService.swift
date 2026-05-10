//
//  FileSystemService.swift
//  ClockSpace
//
//  Extracted from ScreensaverManager (Sprint 2 decomposition).
//  Owns all file-system operations: directory management, permission
//  checks, file copy/move/remove. No UI state — pure I/O layer.
//

import Foundation
#if os(macOS)
import AppKit
#endif

/// Pure file-system operations for screensaver bundle management.
/// No `@Published` state — this is a stateless utility service.
struct FileSystemService {
    
    // MARK: - Singleton
    
    static let shared = FileSystemService()
    private let fm = FileManager.default
    
    private init() {}
    
    // MARK: - Directory Management
    
    /// The user's Screen Savers directory: ~/Library/Screen Savers/
    var screenSaversDirectory: URL {
        let home = fm.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Screen Savers", isDirectory: true)
    }
    
    /// Pre-flight check: can the app write to ~/Library/Screen Savers/?
    var canWrite: Bool {
        let dir = screenSaversDirectory
        if !fm.fileExists(atPath: dir.path) {
            return fm.isWritableFile(atPath: dir.deletingLastPathComponent().path)
        }
        return fm.isWritableFile(atPath: dir.path)
    }
    
    /// Ensure the Screen Savers directory exists, creating it if needed.
    /// - Throws: `ScreensaverInstallError.permissionDenied` if creation fails.
    func ensureDirectory() throws {
        let dir = screenSaversDirectory
        guard !fm.fileExists(atPath: dir.path) else { return }
        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            throw ScreensaverInstallError.permissionDenied(dir.path)
        }
    }
    
    /// Full pre-flight: writable + directory exists.
    func preflight() throws {
        guard canWrite else {
            throw ScreensaverInstallError.permissionDenied(screenSaversDirectory.path)
        }
        try ensureDirectory()
    }
    
    #if os(macOS)
    /// Request the user to manually select the Screen Savers folder.
    /// This is a fallback for when write permissions are denied (e.g. Sandbox).
    func requestManualFolderAccess() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = screenSaversDirectory.deletingLastPathComponent()
        panel.message = "ClockSpace needs permission to manage your Screen Savers. Please select the 'Screen Savers' folder."
        panel.prompt = "Select Folder"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                print("User selected folder: \(url.path)")
                // In a sandboxed app, we would save a security-scoped bookmark here.
            }
        }
    }
    #endif
    
    // MARK: - File Operations
    
    /// Copy a .saver bundle into ~/Library/Screen Savers/, replacing any
    /// existing version.
    ///
    /// - Parameter source: File URL of the .saver bundle.
    /// - Returns: The destination URL.
    /// - Throws: `ScreensaverInstallError` on failure.
    @discardableResult
    func copyToScreenSavers(from source: URL) throws -> URL {
        guard fm.fileExists(atPath: source.path) else {
            throw ScreensaverInstallError.fileNotFound(source)
        }
        guard source.pathExtension.lowercased() == "saver" else {
            throw ScreensaverInstallError.invalidBundle(source.lastPathComponent)
        }
        
        let dest = screenSaversDirectory.appendingPathComponent(source.lastPathComponent)
        
        // Remove existing version if present
        if fm.fileExists(atPath: dest.path) {
            do {
                try fm.removeItem(at: dest)
            } catch {
                throw ScreensaverInstallError.permissionDenied(dest.path)
            }
        }
        
        do {
            try fm.copyItem(at: source, to: dest)
        } catch let error as NSError {
            if error.code == NSFileWriteNoPermissionError {
                throw ScreensaverInstallError.permissionDenied(dest.path)
            }
            throw ScreensaverInstallError.copyFailed(error.localizedDescription)
        }
        
        return dest
    }
    
    /// Remove a single .saver bundle by file name.
    func removeSaver(named fileName: String) {
        let url = screenSaversDirectory.appendingPathComponent(fileName)
        try? fm.removeItem(at: url)
    }
    
    /// Remove ALL .saver bundles that appear to be managed by ClockSpace.
    func removeAllSavers() {
        let contents = (try? fm.contentsOfDirectory(
            at: screenSaversDirectory,
            includingPropertiesForKeys: nil
        )) ?? []
        
        for url in contents where url.pathExtension.lowercased() == "saver" {
            let fileName = url.deletingPathExtension().lastPathComponent
            
            // 1. Check for UUID pattern (legacy naming)
            let uuidPattern = "^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$"
            if fileName.range(of: uuidPattern, options: [.regularExpression, .caseInsensitive]) != nil {
                try? fm.removeItem(at: url)
                continue
            }
            
            // 2. Check for ClockSpace bundle identifier
            let infoPlistPath = url.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
            if let plist = NSDictionary(contentsOf: infoPlistPath),
               let bundleID = plist["CFBundleIdentifier"] as? String,
               bundleID.contains("clockspace") {
                try? fm.removeItem(at: url)
            }
        }
    }
    
    /// Specifically remove UUID-named legacy savers found in the screenshot.
    func cleanUpLegacySavers() {
        removeAllSavers() // Current logic handles UUIDs
    }
    
    /// Resolve a bundled .saver from the app bundle.
    /// Searches `BundledSavers/` subdirectory first, then root Resources.
    ///
    /// - Parameter fileName: e.g. "MyClock.saver"
    /// - Returns: The resolved URL, or `nil` if not found.
    func resolveBundledSaver(fileName: String) -> URL? {
        let name = (fileName as NSString).deletingPathExtension
        
        // 1. Try BundledSavers/ subdirectory
        if let url = Bundle.main.url(forResource: name, withExtension: "saver", subdirectory: "BundledSavers") {
            return url
        }
        // 2. Fallback to root Resources
        return Bundle.main.url(forResource: name, withExtension: "saver")
    }
    
    /// Uninstall a screensaver by removing its bundle from the system directory.
    func uninstall(fileName: String) throws {
        let url = screenSaversDirectory.appendingPathComponent(fileName)
        guard fm.fileExists(atPath: url.path) else { return }
        
        do {
            try fm.removeItem(at: url)
        } catch {
            throw ScreensaverInstallError.permissionDenied(url.path)
        }
    }
    
    /// Clean up a temporary file/directory (best-effort).
    func cleanUp(_ url: URL) {
        try? fm.removeItem(at: url)
    }
}
