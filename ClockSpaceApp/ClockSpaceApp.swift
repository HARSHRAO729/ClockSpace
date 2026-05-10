//
//  ClockSpaceApp.swift
//  ClockSpace
//
//  Main entry point for the ClockSpace marketplace dashboard.
//

import SwiftUI
import AppKit
import FirebaseCore

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        
        // Set Dock Icon programatically if the image exists
        if let image = NSImage(named: "ClockSpace") {
            NSApplication.shared.applicationIconImage = image
        }
    }
}

@main
struct ClockSpaceApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var apiManager = APIManager.shared
    
    // Initializer logic moved to AppDelegate
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(apiManager)
                .preferredColorScheme(.dark)
                .frame(
                    minWidth: CSConstants.Layout.windowMinWidth,
                    maxWidth: CSConstants.Layout.windowMaxWidth,
                    minHeight: CSConstants.Layout.windowMinHeight,
                    maxHeight: CSConstants.Layout.windowMaxHeight
                )
        }
        .defaultSize(
            width: CSConstants.Layout.windowDefaultWidth,
            height: CSConstants.Layout.windowDefaultHeight
        )
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
