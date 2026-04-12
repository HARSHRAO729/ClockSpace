//
//  Category.swift
//  ClockSpace
//
//  Screensaver marketplace categories — content-based taxonomy matching
//  the awesome-macos-screensavers community catalog.
//

import SwiftUI

/// Content-based category taxonomy for the screensaver marketplace.
/// Matches the categories from the awesome-macos-screensavers repo.
enum Category: String, Codable, CaseIterable, Identifiable {
    case clocks = "Clocks"
    case appleInspired = "Apple Inspired"
    case retro = "Retro"
    case sciFi = "Sci-Fi"
    case videoGame = "Video Game"
    case aquarium = "Aquarium"
    case developer = "Developer"
    case graphics = "Graphics"
    case other = "Other"
    case collections = "Collections"
    
    var id: String { rawValue }
    
    /// SF Symbol name for sidebar navigation.
    var iconName: String {
        switch self {
        case .clocks:        return "clock.fill"
        case .appleInspired: return "apple.logo"
        case .retro:         return "arcade.stick"
        case .sciFi:         return "sparkles.tv"
        case .videoGame:     return "gamecontroller.fill"
        case .aquarium:      return "fish.fill"
        case .developer:     return "terminal.fill"
        case .graphics:      return "paintpalette.fill"
        case .other:         return "square.grid.3x3.fill"
        case .collections:   return "rectangle.stack.fill"
        }
    }
    
    /// Short description for category headers.
    var subtitle: String {
        switch self {
        case .clocks:        return "Time displayed in creative ways"
        case .appleInspired: return "Inspired by Apple's iconic designs"
        case .retro:         return "Nostalgic throwback screensavers"
        case .sciFi:         return "Futuristic sci-fi visualizations"
        case .videoGame:     return "Gaming-inspired screen art"
        case .aquarium:      return "Aquatic and underwater scenes"
        case .developer:     return "Built for developers and coders"
        case .graphics:      return "Abstract and generative visuals"
        case .other:         return "Unique and uncategorized gems"
        case .collections:   return "Curated screensaver collections"
        }
    }
    
    /// Accent color per category for visual distinction.
    var tintColor: Color {
        switch self {
        case .clocks:        return Color(hex: 0x22C55E)   // green-500
        case .appleInspired: return Color(hex: 0x3B82F6)   // blue-500
        case .retro:         return Color(hex: 0xF59E0B)   // amber-500
        case .sciFi:         return Color(hex: 0x06B6D4)   // cyan-500
        case .videoGame:     return Color(hex: 0xEF4444)   // red-500
        case .aquarium:      return Color(hex: 0x0EA5E9)   // sky-500
        case .developer:     return Color(hex: 0x10B981)   // emerald-500
        case .graphics:      return Color(hex: 0x8B5CF6)   // violet-500
        case .other:         return Color(hex: 0xEC4899)   // pink-500
        case .collections:   return Color(hex: 0xFBBF24)   // yellow-400
        }
    }
}
