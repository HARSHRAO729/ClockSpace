//
//  FileSystemService.swift
//  ClockSpace
//
//  Extracted from ScreensaverManager (Sprint 2 decomposition).
//  Owns all file-system operations: directory management, permission
//  checks, file copy/move/remove. No UI state — pure I/O layer.
//

import Foundation

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
    
    /// Remove ALL .saver bundles from ~/Library/Screen Savers/.
    func removeAllSavers() {
        let contents = (try? fm.contentsOfDirectory(
            at: screenSaversDirectory,
            includingPropertiesForKeys: nil
        )) ?? []
        
        for url in contents where url.pathExtension.lowercased() == "saver" {
            try? fm.removeItem(at: url)
        }
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
    
    /// Clean up a temporary file/directory (best-effort).
    func cleanUp(_ url: URL) {
        try? fm.removeItem(at: url)
    }
}
