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
    case nature
    case space
    case anime
    case cars
    case city
    case videoGame = "videoGames"
    case sciFi
    case fantasy
    case cats
    case clocks
    case appleInspired
    case retro
    case aquarium
    case developer
    case graphics
    case abstract
    case minimalist
    case collections
    case tech
    case other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .nature: return "Nature"
        case .space: return "Space"
        case .anime: return "Anime"
        case .cars: return "Cars"
        case .city: return "City"
        case .videoGame: return "Video Games"
        case .sciFi: return "Sci-Fi"
        case .fantasy: return "Fantasy"
        case .cats: return "Cats"
        case .clocks: return "Clocks"
        case .appleInspired: return "Apple Inspired"
        case .retro: return "Retro"
        case .aquarium: return "Aquarium"
        case .developer: return "Developer"
        case .graphics: return "Graphics"
        case .abstract: return "Abstract"
        case .minimalist: return "Minimalist"
        case .collections: return "Collections"
        case .tech: return "Tech"
        case .other: return "Other"
        }
    }
    
    /// Image name for the category card in the dashboard.
    var imageName: String {
        switch self {
        case .nature: return "cat_nature"
        case .space: return "cat_space"
        case .anime: return "cat_anime"
        case .cars: return "cat_cars"
        case .city: return "cat_city"
        case .videoGame: return "cat_videogames"
        case .sciFi: return "cat_scifi"
        case .fantasy: return "cat_fantasy"
        case .cats: return "cat_cats"
        case .tech: return "cat_tech"
        default: return "cat_nature" // Fallback
        }
    }
    
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
        case .abstract:      return "waveform.path.ecg"
        case .minimalist:    return "minus"
        case .nature:        return "leaf.fill"
        case .space:         return "sparkles"
        case .anime:         return "person.fill"
        case .cars:          return "car.fill"
        case .city:          return "building.2.fill"
        case .fantasy:       return "wand.and.stars"
        case .cats:          return "pawprint.fill"
        case .tech:          return "cpu"
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
        case .abstract:      return "Artistic and non-representational visuals"
        case .minimalist:    return "Simple, clean, and understated designs"
        case .nature:        return "Serene landscapes and organic elements"
        case .space:         return "Explore the wonders of the cosmos"
        case .anime:         return "Japanese animation inspired art"
        case .cars:          return "High-performance automotive art"
        case .city:          return "Urban landscapes and city lights"
        case .fantasy:       return "Epic fantasy worlds and characters"
        case .cats:          return "Feline friends and cozy scenes"
        case .tech:          return "State-of-the-art technology and code"
        }
    }
    
    /// Accent color per category for visual distinction.
    var tintColor: Color {
        switch self {
        case .clocks:        return Color(hex: 0x22C55E)
        case .appleInspired: return Color(hex: 0x3B82F6)
        case .retro:         return Color(hex: 0xF59E0B)
        case .sciFi:         return Color(hex: 0x06B6D4)
        case .videoGame:     return Color(hex: 0xEF4444)
        case .aquarium:      return Color(hex: 0x0EA5E9)
        case .developer:     return Color(hex: 0x10B981)
        case .graphics:      return Color(hex: 0x8B5CF6)
        case .other:         return Color(hex: 0xEC4899)
        case .collections:   return Color(hex: 0xFBBF24)
        case .abstract:      return Color(hex: 0xD946EF)
        case .minimalist:    return Color(hex: 0x94A3B8)
        case .nature:        return Color(hex: 0x22C55E)
        case .space:         return Color(hex: 0x8B5CF6)
        case .anime:         return Color(hex: 0xEC4899)
        case .cars:          return Color(hex: 0xF97316)
        case .city:          return Color(hex: 0x64748B)
        case .fantasy:       return Color(hex: 0x8B5CF6)
        case .cats:          return Color(hex: 0xF06292)
        case .tech:          return Color(hex: 0x6366F1)
        }
    }
}
