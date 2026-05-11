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
    @State private var isAppReady = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isAppReady {
                    DashboardView()
                        .environmentObject(apiManager)
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                } else {
                    LaunchView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(.dark)
            .frame(
                minWidth: CSConstants.Layout.windowMinWidth,
                maxWidth: CSConstants.Layout.windowMaxWidth,
                minHeight: CSConstants.Layout.windowMinHeight,
                maxHeight: CSConstants.Layout.windowMaxHeight
            )
            .task {
                // Perform initial fetch
                await apiManager.refreshCatalog()
                
                // Allow the splash screen to be seen for at least 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                
                withAnimation(.easeInOut(duration: 0.8)) {
                    isAppReady = true
                }
            }
        }
        .defaultSize(
            width: CSConstants.Layout.windowDefaultWidth,
            height: CSConstants.Layout.windowDefaultHeight
        )
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
