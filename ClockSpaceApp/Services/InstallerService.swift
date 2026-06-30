//
//  InstallerService.swift
//  ClockSpace
//
//  Handles the strategy for installing different types of screensavers.
//  Delegates to FileSystemService and CompilerService.
//

import Foundation

/// Service responsible for the concrete steps to install a screensaver.
/// Handles resolving local bundles vs. compiling remote/template savers.
@MainActor
final class InstallerService {
    
    // MARK: - Singleton
    
    static let shared = InstallerService()
    
    private let fileSystem = FileSystemService.shared
    
    private init() {}
    
    // MARK: - Public API
    
    /// Installs a screensaver based on its download URL.
    /// - Parameter screensaver: The screensaver model to install.
    /// - Throws: `ScreensaverInstallError` if the installation fails.
    @discardableResult
    func install(_ screensaver: Screensaver) async throws -> URL {
        if screensaver.downloadURL.hasPrefix("local://") {
            return try installLocalBundledSaver(screensaver)
        } else if screensaver.downloadURL.hasPrefix("https://") {
            return try await installRemoteDownloadedSaver(screensaver)
        } else {
            throw ScreensaverInstallError.invalidBundle("No valid remote download URL found.")
        }
    }
    
    // MARK: - Private: Installation Strategies
    
    /// Install a screensaver bundled inside the app (local:// protocol).
    private func installLocalBundledSaver(_ screensaver: Screensaver) throws -> URL {
        let bundleFileName = String(screensaver.downloadURL.dropFirst(8))
        
        guard let bundleURL = fileSystem.resolveBundledSaver(fileName: bundleFileName) else {
            let searchPath = Bundle.main.resourcePath ?? "Resources"
            throw ScreensaverInstallError.fileNotFound(
                URL(fileURLWithPath: "\(searchPath)/\(bundleFileName)")
            )
        }
        
        guard FileManager.default.fileExists(atPath: bundleURL.path) else {
            throw ScreensaverInstallError.fileNotFound(bundleURL)
        }
        
        return try fileSystem.copyToScreenSavers(from: bundleURL)
    }
    
    private func installRemoteDownloadedSaver(_ screensaver: Screensaver) async throws -> URL {
        guard let url = URL(string: screensaver.downloadURL) else {
            throw ScreensaverInstallError.copyFailed("Invalid remote URL")
        }
        
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        let safeName = screensaver.name
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
            .lowercased()
        
        let downloadDest = tempDir.appendingPathComponent("\(screensaver.id.uuidString).tmp")
        let extractionDir = tempDir.appendingPathComponent("\(screensaver.id.uuidString)_extract")
        let finalSaverPath = tempDir.appendingPathComponent("\(safeName).saver")
        
        // 1. Download file
        let (localURL, _) = try await URLSession.shared.download(from: url)
        
        // Move to tmp with known name for processing
        if fm.fileExists(atPath: downloadDest.path) { try? fm.removeItem(at: downloadDest) }
        try fm.moveItem(at: localURL, to: downloadDest)
        
        // 2. Handle Zip vs Raw Saver
        if url.pathExtension.lowercased() == "zip" {
            // Unzip using ditto
            if fm.fileExists(atPath: extractionDir.path) { try? fm.removeItem(at: extractionDir) }
            try fm.createDirectory(at: extractionDir, withIntermediateDirectories: true)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-xk", downloadDest.path, extractionDir.path]
            try process.run()
            process.waitUntilExit()
            
            // Find the .saver bundle inside the extracted directory (recursive search)
            let enumerator = fm.enumerator(at: extractionDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            var foundSaver: URL?
            
            while let fileURL = enumerator?.nextObject() as? URL {
                if fileURL.pathExtension.lowercased() == "saver" {
                    foundSaver = fileURL
                    break
                }
            }
            
            if let saverBundle = foundSaver {
                if fm.fileExists(atPath: finalSaverPath.path) { try? fm.removeItem(at: finalSaverPath) }
                try fm.moveItem(at: saverBundle, to: finalSaverPath)
            } else {
                throw ScreensaverInstallError.invalidBundle("No .saver bundle found in the downloaded package.")
            }
        } else {
            // Assume it's a raw .saver bundle
            if fm.fileExists(atPath: finalSaverPath.path) { try? fm.removeItem(at: finalSaverPath) }
            try fm.moveItem(at: downloadDest, to: finalSaverPath)
        }
        
        // 3. Codesign downloaded bundle to run locally
        try? codesign(bundleURL: finalSaverPath)
        
        // 4. Install to system
        let installedURL = try fileSystem.copyToScreenSavers(from: finalSaverPath)
        
        // 5. Cleanup
        try? fm.removeItem(at: downloadDest)
        try? fm.removeItem(at: extractionDir)
        try? fm.removeItem(at: finalSaverPath)
        
        return installedURL
    }
    
    /// Ad-hoc codesign to satisfy Gatekeeper
    private func codesign(bundleURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "codesign --force --sign - \"\(bundleURL.path)\""]
        try process.run()
        process.waitUntilExit()
    }
}
