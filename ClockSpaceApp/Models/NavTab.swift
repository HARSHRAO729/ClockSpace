//
//  NavTab.swift
//  ClockSpace
//
//  Tabs of the main window and the shared navigation state, so both the
//  views and the menu-bar commands (⌘1–3, ⌘F) can change it.
//

import SwiftUI
import Combine

enum NavTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case explore = "Explore"
    case library = "Library"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .home: return "house"
        case .explore: return "safari"
        case .library: return "square.stack"
        }
    }
}

@MainActor
final class NavigationModel: ObservableObject {
    @Published var selectedTab: NavTab = .home
    /// The category page open inside Explore, if any.
    @Published var categoryPage: Category?
    @Published var isSearchPresented = false

    func openCategory(_ category: Category) {
        categoryPage = category
        selectedTab = .explore
    }
}
