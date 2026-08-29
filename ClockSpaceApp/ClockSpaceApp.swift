//
//  ClockSpaceApp.swift
//  ClockSpace
//
//  Main entry point for the ClockSpace marketplace dashboard.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
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
                // Perform initial fetch and minimum splash duration in parallel
                async let fetch: () = apiManager.refreshCatalog()
                async let wait: Void? = try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s minimum
                
                // Wait for both to finish
                _ = await fetch
                _ = await wait
                
                withAnimation(.easeInOut(duration: 0.6)) {
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
