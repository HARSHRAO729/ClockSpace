//
//  ClockSpaceApp.swift
//  ClockSpace
//
//  App entry point: one main window, the Settings window (⌘,) and the Go menu.
//

import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// ClockSpace is a single-window app: closing the window quits it.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct ClockSpaceApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var apiManager = APIManager.shared
    @StateObject private var navigation = NavigationModel()

    var body: some Scene {
        // `Window` (not `WindowGroup`): one main window, no File › New Window.
        Window("ClockSpace", id: "main") {
            DashboardView()
                .environmentObject(apiManager)
                .environmentObject(navigation)
                .preferredColorScheme(.dark)
                .frame(width: CSConstants.Layout.contentWidth,
                       height: CSConstants.Layout.contentHeight)
                .task {
                    // Tests run inside the app; keep them off the network.
                    guard !CSConstants.isRunningTests else { return }
                    // The saved catalog is already showing; this refreshes it from the CDN.
                    await apiManager.refreshCatalog()
                    // At most once a day, and only if enabled in Settings.
                    await UpdateChecker.shared.checkAtLaunchIfDue()
                }
        }
        .windowStyle(.hiddenTitleBar)
        // Fixed size: the window takes exactly the content's size and cannot be resized.
        .windowResizability(.contentSize)
        .commands {
            GoCommands(navigation: navigation, apiManager: apiManager)
        }

        Settings {
            SettingsView()
                .environmentObject(apiManager)
                .preferredColorScheme(.dark)
        }
    }
}

/// The Go menu: ⌘1 Home, ⌘2 Explore, ⌘3 Library, ⌘F Search.
struct GoCommands: Commands {
    @ObservedObject var navigation: NavigationModel
    let apiManager: APIManager

    var body: some Commands {
        CommandMenu("Go") {
            Button("Home") { show(.home) }
                .keyboardShortcut("1", modifiers: .command)
            Button("Explore") { show(.explore) }
                .keyboardShortcut("2", modifiers: .command)
            Button("Library") { show(.library) }
                .keyboardShortcut("3", modifiers: .command)
            Divider()
            Button("Search…") {
                apiManager.detailedScreensaver = nil
                navigation.isSearchPresented = true
            }
            .keyboardShortcut("f", modifiers: .command)
        }
    }

    private func show(_ tab: NavTab) {
        apiManager.detailedScreensaver = nil
        navigation.isSearchPresented = false
        navigation.selectedTab = tab
    }
}
