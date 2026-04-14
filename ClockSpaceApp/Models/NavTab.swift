//
//  NavTab.swift
//  ClockSpace
//
//  Navigation tabs for the main dashboard.
//

import Foundation

enum NavTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case explore = "Explore"
    case library = "Library"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "safari.fill"
        case .library: return "square.stack.fill"
        }
    }
}
