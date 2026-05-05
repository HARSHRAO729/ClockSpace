//
//  CompilerService.swift
//  ClockSpace
//
//  Extracted from ScreensaverManager (Sprint 2 decomposition).
//  Owns all .saver bundle compilation: Swift source generation from
//  templates, swiftc invocation, codesigning, Info.plist creation,
//  and thumbnail embedding.
//

import Foundation
import AppKit

/// Compiles screensaver Swift source into a signed .saver bundle.
/// Stateless — takes a `Screensaver` and returns a ready-to-install bundle URL.
struct CompilerService {
    
    // MARK: - Singleton
    
    static let shared = CompilerService()
    private init() {}
    
    // MARK: - Public API
    
    /// Compile a screensaver template into a complete .saver bundle in the
    /// system temp directory.
    ///
    /// Pipeline: source generation → swiftc → codesign → plist → thumbnail
    ///
    /// - Parameter screensaver: The marketplace screensaver with a `template` field.
    /// - Returns: File URL to the compiled .saver bundle (caller must install or clean up).
    /// - Throws: `ScreensaverInstallError` on compilation or codesigning failure.
    func compile(_ screensaver: Screensaver) throws -> URL {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        let saverName = screensaver.name
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        let className = saverName.replacingOccurrences(of: "-", with: "_")
        let stubURL = tempDir.appendingPathComponent("\(saverName).saver")
        
        // Clean up any previous build artifact
        if fm.fileExists(atPath: stubURL.path) {
            try fm.removeItem(at: stubURL)
        }
        try fm.createDirectory(at: stubURL, withIntermediateDirectories: true)
        
        // 1. Generate Swift source
        let source = generateSwiftSource(for: screensaver, className: className)
        let sourceURL = tempDir.appendingPathComponent("\(saverName).swift")
        try source.write(to: sourceURL, atomically: true, encoding: .utf8)
        
        // 2. Compile to binary
        let binaryDir = stubURL.appendingPathComponent("Contents/MacOS")
        try fm.createDirectory(at: binaryDir, withIntermediateDirectories: true)
        let binaryURL = binaryDir.appendingPathComponent(saverName)
        
        try runCompiler(sourceURL: sourceURL, outputURL: binaryURL)
        
        // 3. Ad-hoc codesign
        try codesign(bundleURL: stubURL)
        
        // 4. Generate Info.plist
        let plistURL = stubURL.appendingPathComponent("Contents/Info.plist")
        try generatePlist(
            at: plistURL,
            bundleName: screensaver.name,
            saverName: saverName,
            className: className
        )
        
        // 5. Embed thumbnail
        let resourcesDir = stubURL.appendingPathComponent("Contents/Resources")
        try fm.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
        embedThumbnail(for: screensaver, in: resourcesDir)
        
        return stubURL
    }
    
    // MARK: - Compilation Pipeline
    
    /// Invoke `swiftc` to compile a ScreenSaverView source into a bundle binary.
    private func runCompiler(sourceURL: URL, outputURL: URL) throws {
        let compileCmd = """
        swiftc -emit-library -Xlinker -bundle \
        -o \(outputURL.path) \(sourceURL.path) \
        -target arm64-apple-macosx14.4 \
        -sdk $(xcrun --show-sdk-path) \
        -framework ScreenSaver -framework AppKit -framework QuartzCore
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", compileCmd]
        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown compiler error"
            throw ScreensaverInstallError.unknown("Compiler Error: \(errorOutput)")
        }
    }
    
    /// Ad-hoc codesign to bypass the Gatekeeper 15-second delay.
    private func codesign(bundleURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "codesign --force --sign - \"\(bundleURL.path)\""]
        try process.run()
        process.waitUntilExit()
        // Non-fatal: codesigning failure degrades UX but doesn't break install
    }
    
    /// Write the Info.plist required by macOS to load the .saver bundle.
    private func generatePlist(
        at url: URL,
        bundleName: String,
        saverName: String,
        className: String
    ) throws {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleName</key>
            <string>\(bundleName)</string>
            <key>CFBundleIdentifier</key>
            <string>com.clockspace.\(saverName)</string>
            <key>CFBundleExecutable</key>
            <string>\(saverName)</string>
            <key>NSPrincipalClass</key>
            <string>\(className)View</string>
            <key>CFBundlePackageType</key>
            <string>BNDL</string>
        </dict>
        </plist>
        """
        try plist.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Embed a thumbnail PNG in the .saver's Resources directory for
    /// display in macOS System Settings.
    private func embedThumbnail(for screensaver: Screensaver, in resourcesDir: URL) {
        var thumbnailData: Data?
        
        // 1. Try to load the exact asset from the app bundle
        if let img = NSImage(named: screensaver.thumbnailURL),
           let tiff = img.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff) {
            thumbnailData = bitmap.representation(using: .png, properties: [:])
        }
        
        // 2. Fallback: generate a branded placeholder
        if thumbnailData == nil {
            thumbnailData = generateFallbackThumbnail(name: screensaver.name)
        }
        
        if let data = thumbnailData {
            try? data.write(to: resourcesDir.appendingPathComponent("thumbnail.png"))
        }
    }
    
    /// Generates a 512×320 branded fallback thumbnail image.
    private func generateFallbackThumbnail(name: String) -> Data? {
        let size = NSSize(width: 512, height: 320)
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Dark background
        NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.08, alpha: 1.0).setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        
        // Centered name
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 48, weight: .bold),
            .foregroundColor: NSColor(white: 0.95, alpha: 1.0)
        ]
        let nameSize = name.size(withAttributes: nameAttrs)
        name.draw(
            at: NSPoint(
                x: (size.width - nameSize.width) / 2,
                y: (size.height - nameSize.height) / 2
            ),
            withAttributes: nameAttrs
        )
        
        // Bottom badge
        let badge = "Generated by ClockSpace"
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: NSColor(white: 0.5, alpha: 1.0)
        ]
        let badgeSize = badge.size(withAttributes: badgeAttrs)
        badge.draw(
            at: NSPoint(
                x: (size.width - badgeSize.width) / 2,
                y: 30
            ),
            withAttributes: badgeAttrs
        )
        
        image.unlockFocus()
        
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
    
    // MARK: - Template Engine
    
    /// Generates the Swift source code for a ScreenSaverView subclass
    /// based on the screensaver's `template` field.
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
                
                if (5...9).contains(min) || (55...59).contains(min) { activeIndices.insert(6); activeIndices.insert(7) }
                else if (10...14).contains(min) || (50...54).contains(min) { activeIndices.insert(3); activeIndices.insert(7) }
                else if (15...19).contains(min) || (45...49).contains(min) { activeIndices.insert(4) }
                else if (20...24).contains(min) || (40...44).contains(min) { activeIndices.insert(5); activeIndices.insert(7) }
                else if (25...29).contains(min) || (35...39).contains(min) { activeIndices.insert(5); activeIndices.insert(6); activeIndices.insert(7) }
                else if (30...34).contains(min) { activeIndices.insert(2) }
                
                if min >= 5 && min <= 34 { activeIndices.insert(9) }
                else if min >= 35 && min <= 59 { activeIndices.insert(8) }
                if min < 5 { activeIndices.insert(22) }
                
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
            
        case "excuses":
            extraState = """
                private let excuses = [
                    "It works on my machine.", "It's not a bug, it's a feature.", "It worked yesterday.",
                    "I didn't touch that part of the code.", "Must be a browser issue.", "That's just a warning, not an error.",
                    "It's a caching issue.", "The API must be down.", "Git must have messed it up.",
                    "That bug was already there.", "I was just testing the limits of quantum computing.",
                    "The code is in a mood today.", "I didn't know that was a requirement.", "It's a limitation of the technology.",
                    "It's failing due to a last-minute change.", "The data must be corrupted.",
                    "It's a problem with the third-party library.", "I was just trying to be clever.",
                    "The specifications were ambiguous.", "I'm not sure what you did, but it's not my fault.",
                    "The compiler is hallucinating.", "I thought I fixed that in the last commit.",
                    "The documentation is lying.", "It's an edge case.", "I was following the standard.",
                    "The server must be overloaded.", "I didn't think anyone would ever do that.",
                    "It worked in the prototype.", "It's a race condition.", "My cat walked over the keyboard.",
                    "The garbage collector hasn't visited yet.", "It's a design choice.", "I'm optimizing for developer happiness.",
                    "The internet is broken.", "It was late and I was tired.", "I'll fix it in the next sprint.",
                    "The QA team is finding bugs that don't exist.", "It's a feature request masquerading as a bug.",
                    "The legacy code is haunted.", "I followed the tutorial exactly.", "The stack overflow answer was wrong.",
                    "It's a cosmic ray issue.", "The hardware is incompatible.", "I'm just a junior developer.",
                    "The senior dev said it was fine.", "It's a known issue that we won't fix.",
                    "The user is using it wrong.", "It's an unpredictable side effect.", "I was just refactoring."
                ]
                private var currentExcuse = ""
                private var lastChangeTime: TimeInterval = 0
                private var opacity: CGFloat = 0
                private var isFadingIn = true
            """
            drawImplementation = """
                let currentTime = CACurrentMediaTime()
                if currentExcuse.isEmpty || currentTime - lastChangeTime > 6.0 {
                    currentExcuse = excuses.randomElement() ?? "Wait, what happened?"
                    lastChangeTime = currentTime
                    opacity = 0
                    isFadingIn = true
                }
                
                if isFadingIn {
                    opacity += 0.02
                    if opacity >= 1.0 { 
                        opacity = 1.0
                        if currentTime - lastChangeTime > 5.0 { isFadingIn = false }
                    }
                } else {
                    opacity -= 0.02
                    if opacity <= 0 { opacity = 0 }
                }

                NSColor.black.setFill()
                rect.fill()
                
                let font = NSFont.monospacedSystemFont(ofSize: bounds.height * 0.045, weight: .medium)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.white.withAlphaComponent(opacity)
                ]
                
                let size = currentExcuse.size(withAttributes: attrs)
                currentExcuse.draw(at: CGPoint(x: bounds.midX - size.width/2, y: bounds.midY - size.height/2), withAttributes: attrs)
                
                let subAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12, weight: .light),
                    .foregroundColor: NSColor.white.withAlphaComponent(opacity * 0.3)
                ]
                let subText = "Developer Excuses • Native Fallback"
                let subSize = subText.size(withAttributes: subAttrs)
                subText.draw(at: CGPoint(x: bounds.midX - subSize.width/2, y: 50), withAttributes: subAttrs)
            """

        default: // Sci-Fi HUD
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
        import QuartzCore

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
