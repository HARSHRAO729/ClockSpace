//
//  ScreensaverManager.swift
//  ClockSpace
//
//  Handles file system operations for installing .saver bundles
//  and launching macOS System Settings to the Screen Saver pane.
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
        case .unknown(let detail):
            return "An unexpected error occurred: \(detail)"
        }
    }
}

/// Manages the lifecycle of screensaver bundles on the local file system.
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
    
    // MARK: - Singleton
    
    static let shared = ScreensaverManager()
    
    private init() {
        // On launch, scan for already-installed screensavers
        scanInstalledScreensavers()
    }
    
    // MARK: - Installation Directory
    
    /// The user's Screen Savers directory: ~/Library/Screen Savers/
    var screenSaversDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Screen Savers", isDirectory: true)
    }
    
    // MARK: - Public API
    
    /// Install a .saver bundle from a source URL into ~/Library/Screen Savers/.
    ///
    /// - Parameter source: The file URL of the .saver bundle to install.
    /// - Returns: The destination URL where the file was copied.
    /// - Throws: `ScreensaverInstallError` on failure.
    @discardableResult
    func installScreensaver(from source: URL) throws -> URL {
        let fileManager = FileManager.default
        
        // 1. Validate the source exists
        guard fileManager.fileExists(atPath: source.path) else {
            throw ScreensaverInstallError.fileNotFound(source)
        }
        
        // 2. Validate it's a .saver bundle
        guard source.pathExtension.lowercased() == "saver" else {
            throw ScreensaverInstallError.invalidBundle(source.lastPathComponent)
        }
        
        // 3. Ensure the destination directory exists
        let destDir = screenSaversDirectory
        if !fileManager.fileExists(atPath: destDir.path) {
            do {
                try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
            } catch {
                throw ScreensaverInstallError.permissionDenied(destDir.path)
            }
        }
        
        // 4. Build destination path
        let destURL = destDir.appendingPathComponent(source.lastPathComponent)
        
        // 5. Check if already installed
        if fileManager.fileExists(atPath: destURL.path) {
            // Remove the old version to allow updates
            do {
                try fileManager.removeItem(at: destURL)
            } catch {
                throw ScreensaverInstallError.permissionDenied(destURL.path)
            }
        }
        
        // 6. Copy the .saver bundle
        do {
            try fileManager.copyItem(at: source, to: destURL)
        } catch let error as NSError {
            if error.code == NSFileWriteNoPermissionError {
                throw ScreensaverInstallError.permissionDenied(destURL.path)
            }
            throw ScreensaverInstallError.copyFailed(error.localizedDescription)
        }
        
        return destURL
    }
    
    /// Simulate an install for a marketplace screensaver (MVP stub).
    /// Creates a placeholder .saver file, copies it to ~/Library/Screen Savers/,
    /// and updates the `installedIDs` set.
    ///
    /// - Parameter screensaver: The marketplace screensaver to "install".
    func installFromMarketplace(_ screensaver: Screensaver) async {
        let id = screensaver.id
        
        // Mark as installing (drives progress UI)
        installingIDs.insert(id)
        lastError = nil
        
        do {
            // Simulate download time
            try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s
            
            // Create a stub .saver placeholder in the temp directory
            let tempDir = FileManager.default.temporaryDirectory
            let saverName = screensaver.name
                .replacingOccurrences(of: " ", with: "-")
                .lowercased()
            let stubURL = tempDir.appendingPathComponent("\(saverName).saver")
            
            // Create a minimal directory bundle to simulate a real .saver
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: stubURL.path) {
                try fileManager.removeItem(at: stubURL)
            }
            try fileManager.createDirectory(at: stubURL, withIntermediateDirectories: true)
            
            // ── COMPILATION: Create a real functional binary ──
            let swiftSource = """
            import ScreenSaver
            import AppKit

            @objc(\(saverName.replacingOccurrences(of: "-", with: "_"))View)
            class \(saverName.replacingOccurrences(of: "-", with: "_"))View: ScreenSaverView {
                private var timeAngle: CGFloat = 0

                override init?(frame: NSRect, isPreview: Bool) {
                    super.init(frame: frame, isPreview: isPreview)
                    animationTimeInterval = 1.0 / 60.0
                }
                required init?(coder: NSCoder) { fatalError() }

                override func draw(_ rect: NSRect) {
                    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
                    
                    // Dark futuristic background
                    NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.08, alpha: 1.0).setFill()
                    rect.fill()
                    
                    let cw = bounds.width
                    let ch = bounds.height
                    let center = CGPoint(x: cw / 2, y: ch / 2)
                    
                    // 1. Draw Vector Grid (Sci-Fi Environment)
                    ctx.setStrokeColor(NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 0.08).cgColor)
                    ctx.setLineWidth(1.0)
                    let gridSize: CGFloat = 80.0
                    for i in 0...Int(cw/gridSize) {
                        ctx.move(to: CGPoint(x: CGFloat(i)*gridSize, y: 0))
                        ctx.addLine(to: CGPoint(x: CGFloat(i)*gridSize, y: ch))
                    }
                    for i in 0...Int(ch/gridSize) {
                        ctx.move(to: CGPoint(x: 0, y: CGFloat(i)*gridSize))
                        ctx.addLine(to: CGPoint(x: cw, y: CGFloat(i)*gridSize))
                    }
                    ctx.strokePath()

                    // Rotate animation state
                    timeAngle += 0.015
                    
                    // 2. Central HUD rings (Sci-Fi Vector Look)
                    ctx.saveGState()
                    ctx.translateBy(x: center.x, y: center.y)
                    
                    // Outer cyan dashed ring
                    ctx.rotate(by: timeAngle * 0.8)
                    let r1 = cw * 0.22
                    let ringRect1 = CGRect(x: -r1, y: -r1, width: r1*2, height: r1*2)
                    ctx.setStrokeColor(NSColor.cyan.withAlphaComponent(0.5).cgColor)
                    ctx.setLineWidth(3.0)
                    ctx.setLineDash(phase: 0, lengths: [40, 15, 5, 15])
                    ctx.strokeEllipse(in: ringRect1)
                    
                    // Inner magenta geometric ring
                    ctx.rotate(by: -timeAngle * 1.8)
                    let r2 = cw * 0.18
                    let ringRect2 = CGRect(x: -r2, y: -r2, width: r2*2, height: r2*2)
                    ctx.setStrokeColor(NSColor.magenta.withAlphaComponent(0.4).cgColor)
                    ctx.setLineWidth(1.5)
                    ctx.setLineDash(phase: 0, lengths: [60, 20])
                    ctx.strokeEllipse(in: ringRect2)
                    
                    ctx.restoreGState()
                    
                    // 3. Render 3D-styled Glowing Time
                    ctx.setShadow(offset: .zero, blur: 20, color: NSColor.cyan.cgColor)
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm:ss"
                    let timeStr = formatter.string(from: Date())
                    
                    let font = NSFont.monospacedDigitSystemFont(ofSize: cw / 10, weight: .bold)
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: NSColor.white
                    ]
                    
                    let size = timeStr.size(withAttributes: attrs)
                    let point = NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2.2)
                    timeStr.draw(at: point, withAttributes: attrs)
                }

                override func animateOneFrame() { 
                    setNeedsDisplay(bounds) 
                }
            }
            """
            let sourceURL = tempDir.appendingPathComponent("\(saverName).swift")
            try swiftSource.write(to: sourceURL, atomically: true, encoding: .utf8)
            
            // Compile to binary
            let binaryDir = stubURL.appendingPathComponent("Contents/MacOS")
            try fileManager.createDirectory(at: binaryDir, withIntermediateDirectories: true)
            let binaryURL = binaryDir.appendingPathComponent("\(saverName)")
            
            let compileCmd = "swiftc -emit-library -o \(binaryURL.path) \(sourceURL.path) -target arm64-apple-macosx14.4 -sdk $(xcrun --show-sdk-path)"
            let compileResult = runShellCommand(compileCmd)
            if compileResult.status != 0 {
                throw ScreensaverInstallError.unknown("Compiler Error: \(compileResult.output)")
            }
            
            // Generate basic thumbnail to override macOS default whirlpool icon
            let resourcesDir = stubURL.appendingPathComponent("Contents/Resources")
            try fileManager.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
            if let iconData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==") {
                try? iconData.write(to: resourcesDir.appendingPathComponent("thumbnail.png"))
            }
            
            // Update Plist with PrincipalClass
            let plistURL = stubURL.appendingPathComponent("Contents/Info.plist")
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleName</key>
                <string>\(screensaver.name)</string>
                <key>CFBundleIdentifier</key>
                <string>com.clockspace.\(screensaver.category.rawValue)</string>
                <key>CFBundleExecutable</key>
                <string>\(saverName)</string>
                <key>NSPrincipalClass</key>
                <string>\(saverName.replacingOccurrences(of: "-", with: "_"))View</string>
                <key>CFBundlePackageType</key>
                <string>BNDL</string>
            </dict>
            </plist>
            """
            try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
            
            // Install from the stub location
            try installScreensaver(from: stubURL)
            
            // Mark as installed
            installedIDs.insert(id)
            persistInstalledIDs()
            
            // Clean up temp stub
            try? fileManager.removeItem(at: stubURL)
            
        } catch let error as ScreensaverInstallError {
            lastError = error
        } catch {
            lastError = .unknown(error.localizedDescription)
        }
        
        // Remove from "installing" state
        installingIDs.remove(id)
    }
    
    /// Uninstall a screensaver by removing it from ~/Library/Screen Savers/.
    func uninstallScreensaver(_ screensaver: Screensaver) {
        let saverName = screensaver.name
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        let saverURL = screenSaversDirectory.appendingPathComponent("\(saverName).saver")
        
        try? FileManager.default.removeItem(at: saverURL)
        installedIDs.remove(screensaver.id)
        persistInstalledIDs()
    }
    
    /// Clears all ClockSpace-related savers from the system for a fresh start.
    func clearAllInstalled() {
        let fileManager = FileManager.default
        let savers = (try? fileManager.contentsOfDirectory(at: screenSaversDirectory, includingPropertiesForKeys: nil)) ?? []
        
        for url in savers {
            if url.lastPathComponent.contains(".saver") {
                // Check if it's one of ours by inspecting the plist or just by name
                try? fileManager.removeItem(at: url)
            }
        }
        
        installedIDs.removeAll()
        activeID = nil
        persistInstalledIDs()
    }
    
    /// Check if a specific screensaver is installed.
    func isInstalled(_ screensaver: Screensaver) -> Bool {
        installedIDs.contains(screensaver.id)
    }
    
    /// Check if a specific screensaver is currently being installed.
    func isInstalling(_ screensaver: Screensaver) -> Bool {
        installingIDs.contains(screensaver.id)
    }
    
    // MARK: - Auto-Apply (Execution Engine)
    
    // WARNING: App Sandbox MUST be disabled in the Xcode target's Signing & Capabilities
    // tab for Process() to successfully modify the system defaults.
    
    /// Programmatically apply the screensaver by modifying the macOS preferences daemon.
    func applyScreensaver(name: String, path: String) -> Bool {
        let fileManager = FileManager.default
        
        // 1. Verify the file actually exists where we think it does
        guard fileManager.fileExists(atPath: path) else {
            let error = "Error: File does not exist at path: \(path)"
            print(error)
            self.lastError = ScreensaverInstallError.fileNotFound(URL(fileURLWithPath: path))
            return false
        }
        
        // 2. Build a robust multi-stage command
        // - xattr: Remove quarantine so macOS doesn't block it
        // - defaults: Write to both Global and Host-specific domains
        // - killall: Wipe preference cache and refresh UI agents
        let command = """
        xattr -cr "\(path)"
        defaults write com.apple.screensaver moduleDict -dict moduleName "\(name)" path "\(path)" type 0
        defaults -currentHost write com.apple.screensaver moduleDict -dict moduleName "\(name)" path "\(path)" type 0
        defaults -currentHost write com.apple.screensaver lastModuleDict -dict moduleName "\(name)" path "\(path)" type 0
        killall cfprefsd || true
        killall WallpaperAgent || true
        killall ScreenSaverEngine || true
        """
        
        print("Executing Apply Command for: \(name)")
        let result = runShellCommand(command)
        
        if result.status != 0 {
            print("Shell Error [\(result.status)]: \(result.output)")
            self.lastError = ScreensaverInstallError.unknown(result.output)
            return false
        }
        
        print("Success: Screensaver applied via shell.")
        return true
    }
    
    private func runShellCommand(_ command: String) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return (process.terminationStatus, output)
        } catch {
            return (-1, error.localizedDescription)
        }
    }
    
    // MARK: - macOS System Settings Handoff
    
    // MARK: - Persistence
    
    /// Scan ~/Library/Screen Savers/ for existing .saver bundles.
    private func scanInstalledScreensavers() {
        // Load persisted IDs from UserDefaults
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
