//
//  ClockSpaceSaverView.swift
//  ClockSpaceSaver
//
//  AppKit ScreenSaverView subclass that bridges to SwiftUI via NSHostingView.
//  This is the principal class loaded by macOS System Settings.
//

import ScreenSaver
import SwiftUI

/// The main screen saver entry point. Hosts a SwiftUI view inside AppKit's ScreenSaverView.
class ClockSpaceSaverView: ScreenSaverView {
    
    // MARK: - Properties
    
    /// The NSHostingView that bridges our SwiftUI content into the AppKit view hierarchy.
    private var hostingView: NSHostingView<ClockSpaceSaverContent>?
    
    /// Whether this instance is rendering in the System Settings preview pane.
    private var isInPreview: Bool = false
    
    // MARK: - Initialization
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.isInPreview = isPreview
        
        // Target 30 FPS — sufficient for smooth clock animation without excessive CPU usage.
        self.animationTimeInterval = 1.0 / 30.0
        
        setupHostingView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        // Screen savers are never loaded from nibs/storyboards.
        // Mark unavailable but satisfy the compiler with a fatalError.
        fatalError("init(coder:) is not supported for screen saver views.")
    }
    
    // MARK: - Setup
    
    /// Creates and embeds the SwiftUI hosting view.
    private func setupHostingView() {
        // Remove any existing hosting view (safety for re-init scenarios)
        hostingView?.removeFromSuperview()
        
        // Create the SwiftUI content, passing preview state for adaptive rendering
        let content = ClockSpaceSaverContent(isPreview: isInPreview)
        let hosting = NSHostingView(rootView: content)
        
        // Fill the entire screen saver frame
        hosting.frame = bounds
        hosting.autoresizingMask = [.width, .height]
        
        // Transparent hosting background so our SwiftUI gradient shows through
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        
        addSubview(hosting)
        self.hostingView = hosting
    }
    
    // MARK: - ScreenSaverView Lifecycle
    
    override func startAnimation() {
        super.startAnimation()
    }
    
    override func stopAnimation() {
        super.stopAnimation()
    }
    
    /// Called each frame — SwiftUI manages its own rendering loop via TimelineView,
    /// so we keep this lightweight.
    override func animateOneFrame() {
        // SwiftUI's TimelineView handles clock updates internally.
        // This override exists to satisfy ScreenSaverView's contract.
        // No-op for the SwiftUI bridge pattern.
    }
    
    override func draw(_ rect: NSRect) {
        // Ensure a black background behind the hosting view
        NSColor.black.setFill()
        rect.fill()
        super.draw(rect)
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        hostingView?.frame = bounds
    }
    
    // MARK: - Configuration Sheet
    
    override var hasConfigureSheet: Bool {
        // No configuration sheet for the MVP.
        return false
    }
    
    override var configureSheet: NSWindow? {
        return nil
    }
}
