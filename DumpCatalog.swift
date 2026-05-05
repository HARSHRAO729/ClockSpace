import Foundation
import SwiftUI

//
//  Screensaver.swift
//  ClockSpace
//
//  Data model representing a screensaver in the marketplace.
//

import Foundation

/// A single screensaver listing in the ClockSpace marketplace.
struct Screensaver: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let category: Category
    let thumbnailURL: String
    let downloadURL: String
    let isPremium: Bool
    let price: Double?
    let author: String
    let downloadCount: Int
    let tags: [String]
    let createdAt: Date
    
    // Wallspace-style Metadata
    let rank: Int?            // 1, 2, 3 for "Most Popular"
    let resolution: String?   // "4K", "1920x1080"
    let fileSize: String?     // "23MB"
    let isNew: Bool           // To show "NEW" badge
    let template: String?     // The code template to use (e.g., "matrix", "flip", "minimal")
    var previewURL: String? = nil   // URL to a video preview
    
    /// Formatted download count (e.g. "12.3K")
    var formattedDownloads: String {
        if downloadCount >= 1_000_000 {
            return String(format: "%.1fM", Double(downloadCount) / 1_000_000)
        } else if downloadCount >= 1_000 {
            return String(format: "%.1fK", Double(downloadCount) / 1_000)
        }
        return "\(downloadCount)"
    }
    
    /// Formatted price string
    var formattedPrice: String {
        guard let price = price, isPremium else { return "Free" }
        return String(format: "$%.2f", price)
    }
}

// MARK: - Install State

/// The possible states of the install CTA button.
enum InstallState {
    case ready       // Default — show "Install" or price
    case installing  // In progress — show spinner
    case installed   // Done — show "Apply" button
    case active      // Active on system — show "Active" checkmark
}
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
    case nature = "Nature"
    case space = "Space"
    case anime = "Anime"
    case cars = "Cars"
    case city = "City"
    case videoGame = "Video Games"
    case sciFi = "Sci-Fi"
    case fantasy = "Fantasy"
    case cats = "Cats"
    case clocks = "Clocks"
    case appleInspired = "Apple Inspired"
    case retro = "Retro"
    case aquarium = "Aquarium"
    case developer = "Developer"
    case graphics = "Graphics"
    case abstract = "Abstract"
    case minimalist = "Minimalist"
    case collections = "Collections"
    case tech = "Tech"
    case other = "Other"
    
    var id: String { rawValue }
    
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
@main
struct DumpCatalog {
    static func main() throws {
        func stableUUID(_ seed: String) -> UUID {
            let hash = seed.utf8.reduce(0) { (acc: UInt64, byte) in
                acc &* 31 &+ UInt64(byte)
            }
            let upper = hash
            let lower = hash &* 6364136223846793005 &+ 1442695040888963407
            let uuid = UUID(uuid: (
                UInt8((upper >> 56) & 0xFF), UInt8((upper >> 48) & 0xFF),
                UInt8((upper >> 40) & 0xFF), UInt8((upper >> 32) & 0xFF),
                UInt8((upper >> 24) & 0xFF), UInt8((upper >> 16) & 0xFF),
                UInt8(((upper >> 8) & 0x0F) | 0x40), UInt8(upper & 0xFF),
                UInt8(((lower >> 56) & 0x3F) | 0x80), UInt8((lower >> 48) & 0xFF),
                UInt8((lower >> 40) & 0xFF), UInt8((lower >> 32) & 0xFF),
                UInt8((lower >> 24) & 0xFF), UInt8((lower >> 16) & 0xFF),
                UInt8((lower >> 8) & 0xFF), UInt8(lower & 0xFF)
            ))
            return uuid
        }

        let mockScreensavers: [Screensaver] = [
        Screensaver(
            id: UUID(uuidString: "f0f0f0f0-f0f0-4f0f-8f0f-f0f0f0f0f0f0")!,
            name: "Forever",
            description: "A beautifully crafted, minimalist clock screensaver that evolves through colors and time. Designed for modern workspaces.",
            category: .minimalist,
            thumbnailURL: "ForeverStars.png",
            downloadURL: "local://forever-stars-macos-screensaver.saver",
            isPremium: true,
            price: nil,
            author: "Forever Stars Team",
            downloadCount: 42,
            tags: ["minimalist", "clock", "modern", "color-fade"],
            createdAt: Date(),
            rank: 1,
            resolution: "5K / Retina",
            fileSize: "4.2 MB",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "2df6cf54-7e84-5477-ab67-b4b4966924fc")!,
            name: "Aerial",
            description: "Locally installed screensaver from source.",
            category: .appleInspired,
            thumbnailURL: "Aerial.gif",
            downloadURL: "local://Aerial.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "03bb1606-79b7-5cf5-8c73-eafd44d9917f")!,
            name: "Blue Screen Saver",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Preview1.gif",
            downloadURL: "local://Blue Screen Saver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "87eb6f35-091d-5bc5-bf73-5b5c5f962e3b")!,
            name: "Brooklyn",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Preview2.gif",
            downloadURL: "local://Brooklyn.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "4e9b2c06-a725-5257-b2e9-7159b9a8d22d")!,
            name: "CircleText",
            description: "Locally installed screensaver from source.",
            category: .minimalist,
            thumbnailURL: "Preview3.gif",
            downloadURL: "local://CircleText.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "31afda90-3d63-5ef1-8ed9-ad7ce36333e3")!,
            name: "ClockOfClocks",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "Preview4.gif",
            downloadURL: "local://ClockOfClocks.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "772abf86-4822-5347-a126-152cdc785e4e")!,
            name: "ColorClockSaver",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "ColorClockSaver.png",
            downloadURL: "local://ColorClockSaver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "787426f0-456e-5097-84d3-9a98b2d74546")!,
            name: "Countdown",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Countdown.gif",
            downloadURL: "local://Countdown.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "ef081f87-e58f-5767-ac42-b82ef1b12b64")!,
            name: "DeveloperExcuses",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Developers-Excuses.jpg",
            downloadURL: "DeveloperExcuses.saver",
            isPremium: false,
            price: nil,
            author: "Local (Fixed)",
            downloadCount: 1337,
            tags: ["local", "source", "fixed"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Native",
            isNew: true,
            template: "excuses"
        ),
        Screensaver(
            id: UUID(uuidString: "d2eeeac6-84fc-5130-bee8-aceeb6e958f6")!,
            name: "Developers Excuses",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Developers-Excuses.jpg",
            downloadURL: "Developers-Excuses.saver",
            isPremium: false,
            price: nil,
            author: "Local (Fixed)",
            downloadCount: 1337,
            tags: ["local", "source", "fixed"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Native",
            isNew: true,
            template: "excuses"
        ),
        Screensaver(
            id: UUID(uuidString: "093f2da9-6fe7-5689-91a1-2b45aefe9e8a")!,
            name: "Ealain",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Dribbble-Screensaver.png",
            downloadURL: "local://Ealain.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "15a82286-0dcd-5373-b96d-a4ba7f162866")!,
            name: "ElectropaintOSX",
            description: "Locally installed screensaver from source.",
            category: .sciFi,
            thumbnailURL: "Preview7.gif",
            downloadURL: "local://ElectropaintOSX.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "e2d2fcaa-c4de-5eec-b63d-bcef624d320a")!,
            name: "Emoji Saver Lite",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "quickgif.gif",
            downloadURL: "local://Emoji Saver Lite.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "2e14bbf9-1d35-552d-8fd4-85419239d7c6")!,
            name: "Emoji Saver",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "space_gophers_animated.gif",
            downloadURL: "local://Emoji Saver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "783bec6c-30dd-59ee-accd-820e479e5bd4")!,
            name: "Epoch Flip Clock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "epochFlipClock.png",
            downloadURL: "local://Epoch Flip Clock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "a5066681-92af-5753-865f-7c7177b0ed60")!,
            name: "Evangelion Clock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "evangelion-clock-red.png",
            downloadURL: "local://Evangelion Clock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "931a0ece-433f-5223-b16a-e05e28f7a039")!,
            name: "Filigree",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "fractalclock-3.png",
            downloadURL: "local://Filigree.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "56905041-5ea9-5a31-83ce-60e3c3e05799")!,
            name: "Fliqlo",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "Preview1.gif",
            downloadURL: "local://Fliqlo.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "fb0b513b-c872-57cf-932a-c88bcfa8e57d")!,
            name: "FractalClock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "FractalClock.png",
            downloadURL: "local://FractalClock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "5fbe46c0-78c8-5e66-ae7e-5f78ebb2b1af")!,
            name: "Fruit",
            description: "Locally installed screensaver from source.",
            category: .nature,
            thumbnailURL: "Preview2.gif",
            downloadURL: "local://Fruit.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "cb9ef674-56c7-5944-9347-4fe488baa37d")!,
            name: "GitHubMatrix",
            description: "Locally installed screensaver from source.",
            category: .sciFi,
            thumbnailURL: "github_matrix.gif",
            downloadURL: "local://GitHubMatrix.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "2ddf074b-0f42-58b7-b94f-17216de3ad61")!,
            name: "Grid Clock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "GridClock.png",
            downloadURL: "local://Grid Clock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "a1d521c0-08d8-5f61-9c9e-50d78c804af0")!,
            name: "HotShotsScreenSaver",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Preview3.gif",
            downloadURL: "local://HotShotsScreenSaver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "f93ff7a3-9ee7-5593-8826-9152e9794cd5")!,
            name: "Irvue Screensaver",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Irvue-Screensaver.png",
            downloadURL: "local://Irvue Screensaver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "593d4380-8fa4-5029-b42f-fd3706588997")!,
            name: "KPSaver",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Preview4.gif",
            downloadURL: "local://KPSaver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "d38a0fd8-e0ad-5791-8c50-483aa23f6856")!,
            name: "Last Statement",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Preview7.gif",
            downloadURL: "local://Last Statement.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "3c9b7457-2841-5a8c-bfae-1dd7c454550d")!,
            name: "Life Saver",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "quickgif.gif",
            downloadURL: "local://Life Saver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "48e541ff-d569-5d6c-99ab-8cda5d880c1f")!,
            name: "Matrix",
            description: "Locally installed screensaver from source.",
            category: .sciFi,
            thumbnailURL: "github_matrix.gif",
            downloadURL: "local://Matrix.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "c66d825f-45d8-5964-a296-1a416094e337")!,
            name: "MinimalClock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "fractalclock-3.png",
            downloadURL: "local://MinimalClock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "890bb9aa-cab9-5f3f-851e-009992f5639a")!,
            name: "MultiClock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "OneClock-Screenshot-Preview.png",
            downloadURL: "local://MultiClock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "e0ae8fb7-4472-509a-ae8d-4e93fb2c3882")!,
            name: "MusaicFM",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "MusaicFM.png",
            downloadURL: "local://MusaicFM.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "358c5110-7abe-57e2-b9ce-4d670df0b08f")!,
            name: "October30",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "October30.gif",
            downloadURL: "local://October30.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "30934b79-f5de-5a78-92ff-0391c3f9b557")!,
            name: "Octoscreen",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Octoscreen.png",
            downloadURL: "local://Octoscreen.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "6c9c77e0-2de0-5aa3-9ba0-0e4729a32318")!,
            name: "OneClock Dial Clock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "oneclock_dial.png",
            downloadURL: "local://OneClock Dial Clock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "2a28c85a-4e9a-58aa-bc5a-2aa0b3cdbc40")!,
            name: "OneClock Digital Clock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "oneclock_digital.png",
            downloadURL: "local://OneClock Digital Clock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "9ee7ee6f-e2df-570d-9a6b-773ebd71bb99")!,
            name: "OneClock Flip Clock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "oneclock_flip.png",
            downloadURL: "local://OneClock Flip Clock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "8c01adf6-f97d-5f2e-becd-644e778195c4")!,
            name: "OneClock ScreenSaver",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "OneClock-Screenshot-Preview.png",
            downloadURL: "local://OneClock ScreenSaver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "94e6505a-3be5-5e46-88b2-77fe89eeed54")!,
            name: "Pasky-Saver",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "demo-paskysaver.gif",
            downloadURL: "local://Pasky-Saver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "918fd9d8-dae6-52d5-8786-24a7b98321b9")!,
            name: "PongSaver",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "pongsaver-1.png",
            downloadURL: "local://PongSaver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "2c114301-fa35-5a8f-a54a-5a1a9d0d05a1")!,
            name: "Predator",
            description: "Locally installed screensaver from source.",
            category: .sciFi,
            thumbnailURL: "predator-preview.png",
            downloadURL: "local://Predator.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "66d5a3e8-6d18-5a72-ab30-a3d885232213")!,
            name: "ScreenMazer",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "ScreenMazer.gif",
            downloadURL: "local://ScreenMazer.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "9c9c9ad2-825e-5195-a734-61f8941d6fcb")!,
            name: "Solar Winds",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "space_gophers_animated.gif",
            downloadURL: "local://Solar Winds.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "f1d0d28b-ef25-5c4e-acdf-22afec96e2a1")!,
            name: "StarWarsScroll",
            description: "Locally installed screensaver from source.",
            category: .sciFi,
            thumbnailURL: "starwarsscroll.png",
            downloadURL: "local://StarWarsScroll.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "62239ab5-56c7-541c-b43e-2bf027e9a200")!,
            name: "Start Now",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Dribbble-Screensaver.png",
            downloadURL: "local://Start Now.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "0a0f36c5-1f97-56b1-a08c-76d59bd6c483")!,
            name: "Today",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Preview1.gif",
            downloadURL: "local://Today.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "97681978-7d51-51b5-aebb-090c86b0c9dc")!,
            name: "WatchScreensaver",
            description: "Locally installed screensaver from source.",
            category: .appleInspired,
            thumbnailURL: "Preview2.gif",
            downloadURL: "local://WatchScreensaver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "71822ba9-6886-5009-b139-ad2d2a9cbc22")!,
            name: "Web",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Preview3.gif",
            downloadURL: "local://Web.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "902e9039-509e-5326-9bb3-8ffffd1c5ecb")!,
            name: "WhatColourIsIt",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "WhatColourIsIt.png",
            downloadURL: "local://WhatColourIsIt.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "00265676-c90c-5676-91e0-bc9f535991d6")!,
            name: "WonderfulTools",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Preview4.gif",
            downloadURL: "local://WonderfulTools.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "95847741-7bbf-5cb9-964a-7fd126f249db")!,
            name: "Word Clock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "Preview7.gif",
            downloadURL: "local://Word Clock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "c1d0e3ac-b44e-51b0-8a35-30a9a028cedc")!,
            name: "iOS Saver",
            description: "Locally installed screensaver from source.",
            category: .appleInspired,
            thumbnailURL: "quickgif.gif",
            downloadURL: "local://iOS Saver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "dd01fda6-2029-5ec8-8d7f-77f851f9b396")!,
            name: "iScreenSaver",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "space_gophers_animated.gif",
            downloadURL: "local://iScreenSaver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "29fe2ccc-686c-58e7-b5b1-8d27a3ed5806")!,
            name: "matrixgl",
            description: "Locally installed screensaver from source.",
            category: .sciFi,
            thumbnailURL: "matrixgl.png",
            downloadURL: "local://matrixgl.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "695b09f1-e3b0-5f35-ad73-44396edd270b")!,
            name: "polar-clock",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "polarclock.png",
            downloadURL: "local://polar-clock.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: UUID(uuidString: "bc70f9f1-3c30-585c-804e-0b2f52c14884")!,
            name: "time-saver",
            description: "Locally installed screensaver from source.",
            category: .clocks,
            thumbnailURL: "Dribbble-Screensaver.png",
            downloadURL: "local://time-saver.saver",
            isPremium: false,
            price: nil,
            author: "Local",
            downloadCount: 0,
            tags: ["local", "source"],
            createdAt: Date(),
            rank: nil,
            resolution: "Retina",
            fileSize: "Local",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: stableUUID("Flux"),
            name: "Flux",
            description: "Organic, flowing shapes that react to time and rhythm. A meditative experience for your desktop.",
            category: .abstract,
            thumbnailURL: "Flux.png",
            downloadURL: "local://flux.saver",
            isPremium: true,
            price: 4.99,
            author: "Abstractio",
            downloadCount: 1240,
            tags: ["organic", "motion", "meditative"],
            createdAt: Date(),
            rank: 2,
            resolution: "5K",
            fileSize: "18MB",
            isNew: true,
            template: "abstract"
        ),
        Screensaver(
            id: stableUUID("Nebula"),
            name: "Nebula",
            description: "A procedurally generated cosmos that slowly swirls across your display.",
            category: .nature,
            thumbnailURL: "Nebula.png",
            downloadURL: "local://nebula.saver",
            isPremium: false,
            price: nil,
            author: "StellarLabs",
            downloadCount: 8900,
            tags: ["space", "cosmos", "slow"],
            createdAt: Date().addingTimeInterval(-86400 * 5),
            rank: 1,
            resolution: "8K",
            fileSize: "45MB",
            isNew: false,
            template: "nature"
        ),
        Screensaver(
            id: stableUUID("MatrixReborn"),
            name: "Matrix Reborn",
            description: "A modern take on the classic digital rain, optimized for high refresh rates.",
            category: .tech,
            thumbnailURL: "Matrix.png",
            downloadURL: "local://matrix.saver",
            isPremium: false,
            price: nil,
            author: "NeoSoftware",
            downloadCount: 15600,
            tags: ["code", "retro", "tech"],
            createdAt: Date().addingTimeInterval(-86400 * 30),
            rank: 3,
            resolution: "4K",
            fileSize: "5MB",
            isNew: false,
            template: "matrix"
        ),
        Screensaver(
            id: stableUUID("ZenGarden"),
            name: "Zen Garden",
            description: "Minimalist ripples and stones that evolve each hour. Perfect for focus work.",
            category: .minimalist,
            thumbnailURL: "ZenGarden.png",
            downloadURL: "local://zen.saver",
            isPremium: true,
            price: 2.99,
            author: "FocusFirst",
            downloadCount: 3200,
            tags: ["calm", "focus", "minimal"],
            createdAt: Date().addingTimeInterval(-86400 * 2),
            rank: 5,
            resolution: "4K",
            fileSize: "12MB",
            isNew: true,
            template: "minimal"
        ),
        Screensaver(
            id: stableUUID("Prism"),
            name: "Prism",
            description: "Light refraction patterns that move with the sun's position. Dynamic and vibrant.",
            category: .abstract,
            thumbnailURL: "Prism.png",
            downloadURL: "local://prism.saver",
            isPremium: true,
            price: 5.99,
            author: "Optics",
            downloadCount: 1100,
            tags: ["light", "dynamic", "vibrant"],
            createdAt: Date(),
            rank: 4,
            resolution: "5K",
            fileSize: "22MB",
            isNew: true,
            template: "prism"
        ),
        Screensaver(
            id: stableUUID("Borealis"),
            name: "Borealis",
            description: "The northern lights captured in a smooth, high-bandwidth simulation.",
            category: .nature,
            thumbnailURL: "Borealis.png",
            downloadURL: "local://borealis.saver",
            isPremium: false,
            price: nil,
            author: "NorthernExp",
            downloadCount: 7500,
            tags: ["nature", "lights", "smooth"],
            createdAt: Date().addingTimeInterval(-86400 * 10),
            rank: 8,
            resolution: "4K",
            fileSize: "38MB",
            isNew: false,
            template: "nature"
        ),
        Screensaver(
            id: stableUUID("Circuitry"),
            name: "Circuitry",
            description: "Data pulses traveling through a sprawling motherboard. Interactive and tech-focused.",
            category: .tech,
            thumbnailURL: "Circuitry.png",
            downloadURL: "local://circuitry.saver",
            isPremium: true,
            price: 3.99,
            author: "ByteBound",
            downloadCount: 4500,
            tags: ["tech", "lines", "fast"],
            createdAt: Date().addingTimeInterval(-86400 * 3),
            rank: 6,
            resolution: "4K",
            fileSize: "15MB",
            isNew: true,
            template: "tech"
        ),
        Screensaver(
            id: stableUUID("Monolith"),
            name: "Monolith",
            description: "A silent, rotating structure in a vast desert. Stoic and powerful.",
            category: .minimalist,
            thumbnailURL: "Monolith.png",
            downloadURL: "local://monolith.saver",
            isPremium: false,
            price: nil,
            author: "Kinesis",
            downloadCount: 2800,
            tags: ["3d", "minimal", "desert"],
            createdAt: Date().addingTimeInterval(-86400 * 20),
            rank: 10,
            resolution: "8K",
            fileSize: "60MB",
            isNew: false,
            template: "minimal"
        ),
        Screensaver(
            id: stableUUID("Solar"),
            name: "Solar",
            description: "Real-time solar flares and surface activity from current satellite data.",
            category: .nature,
            thumbnailURL: "Solar.png",
            downloadURL: "local://solar.saver",
            isPremium: true,
            price: 6.99,
            author: "AstroData",
            downloadCount: 950,
            tags: ["real-time", "sun", "science"],
            createdAt: Date(),
            rank: 12,
            resolution: "4K",
            fileSize: "120MB",
            isNew: true,
            template: "nature"
        ),
        Screensaver(
            id: stableUUID("Oscillate"),
            name: "Oscillate",
            description: "Waveforms that translate system audio into visual patterns.",
            category: .tech,
            thumbnailURL: "Oscillate.png",
            downloadURL: "local://oscillate.saver",
            isPremium: false,
            price: nil,
            author: "AudioViz",
            downloadCount: 5200,
            tags: ["audio", "reactive", "waves"],
            createdAt: Date().addingTimeInterval(-86400 * 15),
            rank: 7,
            resolution: "Retina",
            fileSize: "8MB",
            isNew: false,
            template: "tech"
        )
    ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(mockScreensavers)
        try data.write(to: URL(fileURLWithPath: "ClockSpaceApp/Resources/catalog.json"))
        print("Successfully wrote catalog.json with \(mockScreensavers.count) items.")
    }
}
