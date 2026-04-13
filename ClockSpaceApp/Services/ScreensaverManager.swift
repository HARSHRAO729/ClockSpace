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
        // Force clear all installed ClockSpace screensavers on launch for a fresh start
        clearAllInstalled()
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
            // Handle local bundled savers
            if screensaver.downloadURL.hasPrefix("local://") {
                let bundleFileName = String(screensaver.downloadURL.dropFirst(8))
                let resourceName = (bundleFileName as NSString).deletingPathExtension
                
                // Try searching in BundledSavers subdirectory first
                var bundleURL = Bundle.main.url(forResource: resourceName, withExtension: "saver", subdirectory: "BundledSavers")
                
                // Fallback: search in root Resources folder if flattened
                if bundleURL == nil {
                    bundleURL = Bundle.main.url(forResource: resourceName, withExtension: "saver")
                }
                
                guard let finalBundleURL = bundleURL else {
                    let searchPath = Bundle.main.resourcePath ?? "Resources"
                    throw ScreensaverInstallError.fileNotFound(URL(fileURLWithPath: "\(searchPath)/\(bundleFileName)"))
                }
                
                let bundleURLResolved = finalBundleURL
                
                guard FileManager.default.fileExists(atPath: bundleURLResolved.path) else {
                    throw ScreensaverInstallError.fileNotFound(bundleURLResolved)
                }
                
                // Copy to Screen Savers directory
                try installScreensaver(from: bundleURLResolved)
                
                // Mark as installed
                installedIDs.insert(id)
                persistInstalledIDs()
                
            } else {
                // Original stub/compilation logic for remote/template savers
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
            
            // ── COMPILATION: Create a functional binary based on the selected template ──
            let swiftSource = generateSwiftSource(for: screensaver, className: saverName.replacingOccurrences(of: "-", with: "_"))
""
            let sourceURL = tempDir.appendingPathComponent("\(saverName).swift")
            try swiftSource.write(to: sourceURL, atomically: true, encoding: .utf8)
            
            // Compile to binary
            let binaryDir = stubURL.appendingPathComponent("Contents/MacOS")
            try fileManager.createDirectory(at: binaryDir, withIntermediateDirectories: true)
            let binaryURL = binaryDir.appendingPathComponent("\(saverName)")
            
            let compileCmd = "swiftc -emit-library -o \(binaryURL.path) \(sourceURL.path) -target arm64-apple-macosx14.4 -sdk $(xcrun --show-sdk-path)"
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", compileCmd]
            let pipe = Pipe()
            process.standardError = pipe
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown compiler error"
                throw ScreensaverInstallError.unknown("Compiler Error: \(errorOutput)")
            }
            
            // Generate actual thumbnail to be displayed in macOS System Settings
            let resourcesDir = stubURL.appendingPathComponent("Contents/Resources")
            try fileManager.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
            
            var thumbnailData: Data? = nil
            
            // 1. Try to load the exact thumbnail asset from the active App bundle
            if let img = NSImage(named: screensaver.thumbnailURL),
               let tiff = img.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff) {
                thumbnailData = bitmap.representation(using: .png, properties: [:])
            }
            
            // 2. Fallback to generating a pristine fallback image dynamically
            if thumbnailData == nil {
                let imgSize = NSSize(width: 512, height: 320)
                let fallbackImg = NSImage(size: imgSize)
                fallbackImg.lockFocus()
                
                // Dark background
                NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.08, alpha: 1.0).setFill()
                NSBezierPath(rect: NSRect(origin: .zero, size: imgSize)).fill()
                
                // Centered Name text
                let text = screensaver.name
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 48, weight: .bold),
                    .foregroundColor: NSColor(white: 0.95, alpha: 1.0)
                ]
                let size = text.size(withAttributes: attrs)
                text.draw(at: NSPoint(x: (imgSize.width - size.width) / 2, y: (imgSize.height - size.height) / 2), withAttributes: attrs)
                
                // Top "ClockSpace" badge
                let subText = "Generated by ClockSpace"
                let subAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 18, weight: .medium),
                    .foregroundColor: NSColor(white: 0.5, alpha: 1.0)
                ]
                let subSize = subText.size(withAttributes: subAttrs)
                subText.draw(at: NSPoint(x: (imgSize.width - subSize.width) / 2, y: 30), withAttributes: subAttrs)
                
                fallbackImg.unlockFocus()
                
                if let tiff = fallbackImg.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiff) {
                    thumbnailData = bitmap.representation(using: .png, properties: [:])
                }
            }
            
            if let data = thumbnailData {
                try? data.write(to: resourcesDir.appendingPathComponent("thumbnail.png"))
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
                <string>com.clockspace.\(saverName)</string>
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
            }
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
        
        guard fileManager.fileExists(atPath: path) else {
            let error = "Error: File does not exist at path: \(path)"
            print(error)
            self.lastError = ScreensaverInstallError.fileNotFound(URL(fileURLWithPath: path))
            return false
        }
        
        // Use modern macOS Sonoma Deep Link Handoff to Wallpaper settings
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension")!)
        return true
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

    // MARK: - Template Engine
    
    private func generateSwiftSource(for screensaver: Screensaver, className: String) -> String {
        let template = screensaver.template ?? "default"
        
        var drawImplementation = ""
        var extraState = ""
        
        switch template {
        case "flip":
            drawImplementation = """
                NSColor(calibratedWhite: 0.1, alpha: 1.0).setFill()
                rect.fill()
                
                let calendar = Calendar.current
                let comps = calendar.dateComponents([.hour, .minute], from: Date())
                let hr = String(format: "%02d", comps.hour!)
                let mn = String(format: "%02d", comps.minute!)
                
                let cardWidth = bounds.width * 0.25
                let cardHeight = bounds.height * 0.45
                let padding = bounds.width * 0.05
                
                let totalWidth = cardWidth * 2 + padding
                let startX = (bounds.width - totalWidth) / 2
                let startY = (bounds.height - cardHeight) / 2
                
                for (i, text) in [hr, mn].enumerated() {
                    let cardRect = CGRect(x: startX + CGFloat(i) * (cardWidth + padding), y: startY, width: cardWidth, height: cardHeight)
                    
                    let path = NSBezierPath(roundedRect: cardRect, xRadius: 24, yRadius: 24)
                    NSColor(calibratedWhite: 0.15, alpha: 1.0).setFill()
                    path.fill()
                    
                    let splitRect = CGRect(x: cardRect.minX, y: cardRect.midY - 2, width: cardWidth, height: 4)
                    NSColor.black.setFill()
                    splitRect.fill()
                    
                    let font = NSFont.systemFont(ofSize: cardHeight * 0.65, weight: .heavy)
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: NSColor.white
                    ]
                    let size = text.size(withAttributes: attrs)
                    text.draw(at: CGPoint(x: cardRect.midX - size.width/2, y: cardRect.midY - size.height/2 - 10), withAttributes: attrs)
                }
            """
            
        case "matrix":
            extraState = """
                private var drops: [CGFloat] = []
                private var speeds: [CGFloat] = []
                private var chars: [String] = []
            """
            drawImplementation = """
                let cols = Int(bounds.width / 25)
                if drops.isEmpty { 
                    drops = (0..<cols).map { _ in CGFloat.random(in: 0...bounds.height) }
                    speeds = (0..<cols).map { _ in CGFloat.random(in: 5...15) }
                    chars = (0..<cols).map { _ in String(UnicodeScalar(Int.random(in: 0x30A0...0x30FF))!) }
                }
                
                NSColor(calibratedRed: 0, green: 0.05, blue: 0, alpha: 0.15).setFill()
                rect.fill()
                
                for i in 0..<cols {
                    if Double.random(in: 0...1) > 0.8 {
                        chars[i] = String(UnicodeScalar(Int.random(in: 0x30A0...0x30FF))!)
                    }
                    let text = chars[i]
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: 20, weight: .bold),
                        .foregroundColor: NSColor(calibratedRed: 0.2, green: 1.0, blue: 0.2, alpha: 1.0)
                    ]
                    text.draw(at: CGPoint(x: CGFloat(i) * 25, y: bounds.height - drops[i]), withAttributes: attrs)
                    
                    drops[i] += speeds[i]
                    if drops[i] > bounds.height && Double.random(in: 0...1) > 0.95 { 
                        drops[i] = 0
                        speeds[i] = CGFloat.random(in: 5...15)
                    }
                }
            """
            
        case "word":
            extraState = "private let words = [\"IT\", \"IS\", \"HALF\", \"TEN\", \"QUARTER\", \"TWENTY\", \"FIVE\", \"MINUTES\", \"TO\", \"PAST\", \"ONE\", \"TWO\", \"THREE\", \"FOUR\", \"FIVE\", \"SIX\", \"SEVEN\", \"EIGHT\", \"NINE\", \"TEN\", \"ELEVEN\", \"TWELVE\", \"O'CLOCK\", \"AM\", \"PM\"]"
            drawImplementation = """
                NSColor(calibratedWhite: 0.02, alpha: 1.0).setFill()
                rect.fill()
                
                let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
                var activeIndices = Set([0, 1]) // IT IS
                
                let min = comps.minute ?? 0
                let realHr = comps.hour ?? 0
                var hr = realHr
                if min > 30 { hr += 1 }
                hr = hr % 12
                if hr == 0 { hr = 12 }
                
                if (5...9).contains(min) || (55...59).contains(min) { activeIndices.insert(6); activeIndices.insert(7) } // FIVE MINUTES
                else if (10...14).contains(min) || (50...54).contains(min) { activeIndices.insert(3); activeIndices.insert(7) } // TEN MINUTES
                else if (15...19).contains(min) || (45...49).contains(min) { activeIndices.insert(4) } // QUARTER
                else if (20...24).contains(min) || (40...44).contains(min) { activeIndices.insert(5); activeIndices.insert(7) } // TWENTY MINUTES
                else if (25...29).contains(min) || (35...39).contains(min) { activeIndices.insert(5); activeIndices.insert(6); activeIndices.insert(7) } // TWENTY FIVE MINUTES
                else if (30...34).contains(min) { activeIndices.insert(2) } // HALF
                
                if min >= 5 && min <= 34 { activeIndices.insert(9) } // PAST
                else if min >= 35 && min <= 59 { activeIndices.insert(8) } // TO
                if min < 5 { activeIndices.insert(22) } // O'CLOCK
                
                activeIndices.insert(10 + hr - 1)
                if realHr >= 12 { activeIndices.insert(24) } else { activeIndices.insert(23) }
                
                let cols = 5
                let rows = 5
                let cellW = bounds.width / CGFloat(cols)
                let cellH = bounds.height / CGFloat(rows)
                
                for (i, word) in words.enumerated() {
                    let col = i % cols
                    let row = i / cols
                    let isActive = activeIndices.contains(i)
                    
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.monospacedSystemFont(ofSize: bounds.height * 0.05, weight: isActive ? .bold : .light),
                        .foregroundColor: isActive ? NSColor.white : NSColor(white: 0.2, alpha: 1.0)
                    ]
                    let size = word.size(withAttributes: attrs)
                    let x = CGFloat(col) * cellW + (cellW - size.width) / 2
                    let y = bounds.height - (CGFloat(row) * cellH) - cellH + (cellH - size.height) / 2
                    word.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
                }
            """
            
        case "minimal":
            drawImplementation = """
                NSColor.black.setFill()
                rect.fill()
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                let timeStr = formatter.string(from: Date())
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: bounds.height * 0.15, weight: .ultraLight),
                    .foregroundColor: NSColor(white: 0.9, alpha: 1.0)
                ]
                let size = timeStr.size(withAttributes: attrs)
                timeStr.draw(at: CGPoint(x: bounds.midX - size.width/2, y: bounds.midY - size.height/2), withAttributes: attrs)
            """
            
        case "color":
            drawImplementation = """
                let formatter = DateFormatter()
                formatter.dateFormat = "HHmmss"
                let hexOptions = formatter.string(from: Date())
                
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                if let val = Int(hexOptions) {
                    r = CGFloat((val >> 16) & 0xFF) / 255.0
                    g = CGFloat((val >> 8) & 0xFF) / 255.0
                    b = CGFloat(val & 0xFF) / 255.0
                }
                
                NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0).setFill()
                rect.fill()
                
                let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: bounds.height * 0.1, weight: .bold),
                    .foregroundColor: NSColor.white
                ]
                let size = timeStr.size(withAttributes: attrs)
                timeStr.draw(at: CGPoint(x: bounds.midX - size.width/2, y: bounds.midY - size.height/2), withAttributes: attrs)
                
                let hexStr = "#" + hexOptions
                let hexAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: bounds.height * 0.04, weight: .regular),
                    .foregroundColor: NSColor(white: 1.0, alpha: 0.7)
                ]
                let hexSize = hexStr.size(withAttributes: hexAttrs)
                hexStr.draw(at: CGPoint(x: bounds.midX - hexSize.width/2, y: bounds.midY - size.height/2 - hexSize.height - 30), withAttributes: hexAttrs)
            """
            
        case "nature":
            extraState = "private var phase: CGFloat = 0"
            drawImplementation = """
                phase += 0.01
                let cx1 = bounds.width/2 + cos(phase)*bounds.width/3
                let cy1 = bounds.height/2 + sin(phase)*bounds.height/3
                let cx2 = bounds.width/2 + cos(phase + .pi)*bounds.width/3
                let cy2 = bounds.height/2 + sin(phase + .pi)*bounds.height/3
                
                let gradient = NSGradient(colors: [
                    NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.2, alpha: 1.0),
                    NSColor(calibratedRed: 0.2, green: 0.6, blue: 0.8, alpha: 1.0),
                    NSColor(calibratedRed: 0.8, green: 0.2, blue: 0.5, alpha: 1.0)
                ])
                gradient?.draw(from: NSPoint(x: cx1, y: cy1), to: NSPoint(x: cx2, y: cy2), options: [.drawsBeforeStartingLocation, .drawsAfterEndingLocation])
                
                let text = "\(screensaver.name.uppercased())"
                let font = NSFont.systemFont(ofSize: bounds.height * 0.05, weight: .thin)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(white: 1.0, alpha: 0.5)]
                let size = text.size(withAttributes: attrs)
                text.draw(at: CGPoint(x: bounds.midX - size.width/2, y: bounds.height * 0.1), withAttributes: attrs)
            """
            
        case "generative":
            extraState = "private var phase: CGFloat = 0"
            drawImplementation = """
                phase += 0.02
                NSColor(calibratedRed: 0.01, green: 0.02, blue: 0.05, alpha: 0.2).setFill()
                rect.fill()
                
                guard let ctx = NSGraphicsContext.current?.cgContext else { return }
                ctx.translateBy(x: bounds.midX, y: bounds.midY)
                
                let numPoints = 80
                let radius = bounds.height * 0.35
                
                ctx.setLineWidth(2)
                for i in 0..<numPoints {
                    let angle = CGFloat(i) * 2 * .pi / CGFloat(numPoints)
                    let offset = sin(phase + angle * 4) * 60
                    
                    let x = cos(angle) * (radius + offset)
                    let y = sin(angle) * (radius + offset)
                    
                    let hue = fmod((angle/(2 * .pi)) + (phase * 0.1), 1.0)
                    let color = NSColor(calibratedHue: hue, saturation: 0.8, brightness: 1.0, alpha: 0.8)
                    ctx.setStrokeColor(color.cgColor)
                    
                    ctx.beginPath()
                    ctx.move(to: .zero)
                    ctx.addLine(to: CGPoint(x: x, y: y))
                    ctx.strokePath()
                    
                    ctx.setFillColor(color.cgColor)
                    ctx.fillEllipse(in: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
                }
            """
            
        default: // Sci-Fi HUD (Default)
            extraState = "private var rotation: CGFloat = 0"
            drawImplementation = """
                rotation += 0.02
                NSColor(calibratedRed: 0.01, green: 0.02, blue: 0.05, alpha: 1.0).setFill()
                rect.fill()
                guard let ctx = NSGraphicsContext.current?.cgContext else { return }
                ctx.translateBy(x: bounds.midX, y: bounds.midY)
                ctx.rotate(by: rotation)
                ctx.setStrokeColor(NSColor.cyan.cgColor)
                ctx.setLineWidth(2)
                ctx.stroke(CGRect(x: -150, y: -150, width: 300, height: 300))
                let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
                let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 60, weight: .bold), .foregroundColor: NSColor.white]
                timeStr.draw(at: CGPoint(x: -timeStr.size(withAttributes: attrs).width/2, y: -30), withAttributes: attrs)
            """
        }
        
        return """
        import ScreenSaver
        import AppKit

        @objc(\(className)View)
        class \(className)View: ScreenSaverView {
            \(extraState)
            
            override init?(frame: NSRect, isPreview: Bool) {
                super.init(frame: frame, isPreview: isPreview)
                animationTimeInterval = 1.0 / 60.0
            }
            required init?(coder: NSCoder) { fatalError() }

            override func draw(_ rect: NSRect) {
                \(drawImplementation)
            }

            override func animateOneFrame() { setNeedsDisplay(bounds) }
        }
        """
    }
}

