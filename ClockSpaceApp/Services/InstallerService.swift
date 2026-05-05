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
    private let compiler = CompilerService.shared
    
    private init() {}
    
    // MARK: - Public API
    
    /// Installs a screensaver based on its download URL.
    /// - Parameter screensaver: The screensaver model to install.
    /// - Throws: `ScreensaverInstallError` if the installation fails.
    func install(_ screensaver: Screensaver) async throws {
        if screensaver.downloadURL.hasPrefix("local://") {
            try installLocalBundledSaver(screensaver)
        } else {
            try await installCompiledSaver(screensaver)
        }
    }
    
    // MARK: - Private: Installation Strategies
    
    /// Install a screensaver bundled inside the app (local:// protocol).
    private func installLocalBundledSaver(_ screensaver: Screensaver) throws {
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
        
        try fileSystem.copyToScreenSavers(from: bundleURL)
    }
    
    /// Compile a screensaver from its template and install the result.
    private func installCompiledSaver(_ screensaver: Screensaver) async throws {
        // Simulate download latency for remote savers
        try await Task.sleep(nanoseconds: 1_200_000_000)
        
        // Compile → returns temp .saver bundle URL
        let compiledURL = try compiler.compile(screensaver)
        
        // Install from temp location
        try fileSystem.copyToScreenSavers(from: compiledURL)
        
        // Clean up temp build artifact
        fileSystem.cleanUp(compiledURL)
    }
}
