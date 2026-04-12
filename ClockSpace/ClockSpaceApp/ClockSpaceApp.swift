//
//  ClockSpaceApp.swift
//  ClockSpace
//
//  Main entry point for the ClockSpace marketplace dashboard.
//

import SwiftUI

@main
struct ClockSpaceApp: App {
    
    @StateObject private var apiManager = APIManager.shared
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(apiManager)
                .preferredColorScheme(.dark)
                .frame(
                    minWidth: CSConstants.Layout.windowMinWidth,
                    minHeight: CSConstants.Layout.windowMinHeight
                )
        }
        .defaultSize(
            width: CSConstants.Layout.windowDefaultWidth,
            height: CSConstants.Layout.windowDefaultHeight
        )
        .windowStyle(.hiddenTitleBar)
    }
}
