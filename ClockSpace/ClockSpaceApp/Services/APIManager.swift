//
//  APIManager.swift
//  ClockSpace
//
//  Stubbed API service for the screensaver marketplace.
//  Returns mock data for the MVP. Swap implementations for production.
//

import Foundation
import Combine

/// Protocol for dependency injection and testability.
protocol ScreensaverServiceProtocol {
    func fetchScreensavers(category: Category?) async throws -> [Screensaver]
    func searchScreensavers(query: String) async throws -> [Screensaver]
    func downloadScreensaver(id: UUID) async throws -> URL
}

/// Stubbed API manager returning hardcoded mock data.
@MainActor
final class APIManager: ObservableObject, ScreensaverServiceProtocol {
    
    // MARK: - Published State
    
    @Published var screensavers: [Screensaver] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var detailedScreensaver: Screensaver? = nil
    @Published var likedIDs: Set<UUID> = []
    @Published var selectedCategory: Category? = nil
    
    // MARK: - Singleton
    
    static let shared = APIManager()
    
    private init() {
        // Mock some liked items
        loadLikedItems()
    }
    
    func toggleLiked(_ saver: Screensaver) {
        if likedIDs.contains(saver.id) {
            likedIDs.remove(saver.id)
        } else {
            likedIDs.insert(saver.id)
        }
        saveLikedItems()
    }
    
    func isLiked(_ saver: Screensaver) -> Bool {
        likedIDs.contains(saver.id)
    }
    
    private func saveLikedItems() {
        if let data = try? JSONEncoder().encode(likedIDs) {
            UserDefaults.standard.set(data, forKey: "cs_liked_ids")
        }
    }
    
    private func loadLikedItems() {
        if let data = UserDefaults.standard.data(forKey: "cs_liked_ids"),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            likedIDs = ids
        }
    }
    
    // MARK: - Public API
    
    /// Fetch screensavers, optionally filtered by category.
    func fetchScreensavers(category: Category? = nil) async throws -> [Screensaver] {
        isLoading = true
        errorMessage = nil
        
        // Simulate network latency
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        let allSavers = Self.mockScreensavers
        let filtered: [Screensaver]
        
        if let category = category {
            filtered = allSavers.filter { $0.category == category }
        } else {
            filtered = allSavers
        }
        
        screensavers = filtered
        isLoading = false
        return filtered
    }
    
    /// Search screensavers by name or tag.
    func searchScreensavers(query: String) async throws -> [Screensaver] {
        isLoading = true
        errorMessage = nil
        
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        let lowered = query.lowercased()
        let results = Self.mockScreensavers.filter { saver in
            saver.name.lowercased().contains(lowered) ||
            saver.author.lowercased().contains(lowered) ||
            saver.tags.contains(where: { $0.lowercased().contains(lowered) })
        }
        
        screensavers = results
        isLoading = false
        return results
    }
    
    /// Stub: returns a placeholder file URL for the downloaded screensaver.
    func downloadScreensaver(id: UUID) async throws -> URL {
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("\(id.uuidString).saver")
    }
    
    // MARK: - Deterministic UUID Helper
    
    private static func stableUUID(_ seed: String) -> UUID {
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
    
    // MARK: - Complete Screensaver Catalog (43 entries)
    
    private static let mockScreensavers: [Screensaver] = [
        
        // ── CLOCKS ──
        
        Screensaver(
            id: stableUUID("fliqlo"),
            name: "Fliqlo",
            description: "A retro-style flip clock screensaver with elegant mechanical card-flip animations.",
            category: .clocks,
            thumbnailURL: "fliqlo",
            downloadURL: "https://fliqlo.com",
            isPremium: false,
            price: nil,
            author: "Yuji Adachi",
            downloadCount: 184_500,
            tags: ["clock", "flip", "retro", "minimal"],
            createdAt: Date().addingTimeInterval(-86400 * 365),
            rank: 1,
            resolution: "Retina",
            fileSize: "3MB",
            isNew: false,
            template: "flip"
        ),
        
        Screensaver(
            id: stableUUID("today"),
            name: "Today",
            description: "Time and date in stylings inspired by On Kawara's paintings.",
            category: .clocks,
            thumbnailURL: "today",
            downloadURL: "https://github.com/jacklatimer/today",
            isPremium: false,
            price: nil,
            author: "Jack Latimer",
            downloadCount: 12_400,
            tags: ["clock", "art", "minimal"],
            createdAt: Date().addingTimeInterval(-86400 * 200),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("word-clock-circular"),
            name: "Word Clock",
            description: "A beautifully crafted clock made entirely of words.",
            category: .clocks,
            thumbnailURL: "word_clock",
            downloadURL: "https://www.simonheys.com/wordclock/",
            isPremium: false,
            price: nil,
            author: "Simon Heys",
            downloadCount: 34_200,
            tags: ["clock", "words", "typography"],
            createdAt: Date().addingTimeInterval(-86400 * 300),
            rank: 3,
            resolution: "Retina",
            fileSize: "4MB",
            isNew: false,
            template: "word"
        ),
        
        Screensaver(
            id: stableUUID("fractal-clock"),
            name: "Fractal Clock",
            description: "Clock that generates evolving fractal tree patterns.",
            category: .clocks,
            thumbnailURL: "fractal_clock",
            downloadURL: "https://github.com/fractalclock",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 18_700,
            tags: ["clock", "fractal", "generative"],
            createdAt: Date().addingTimeInterval(-86400 * 250),
            rank: nil,
            resolution: "4K",
            fileSize: "5MB",
            isNew: false,
            template: "generative"
        ),
        
        Screensaver(
            id: stableUUID("epoch-flip-clock"),
            name: "Epoch Flip Clock",
            description: "Unix epoch time displayed as a flip clock.",
            category: .clocks,
            thumbnailURL: "epoch_flip",
            downloadURL: "https://github.com/epochflipclock",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 8_200,
            tags: ["clock", "unix", "epoch"],
            createdAt: Date().addingTimeInterval(-86400 * 180),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false,
            template: "flip"
        ),
        
        Screensaver(
            id: stableUUID("grid-clock"),
            name: "Grid Clock",
            description: "Twelve-hour time expressed in English words in a grid.",
            category: .clocks,
            thumbnailURL: "grid_clock",
            downloadURL: "https://github.com/gridclock",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 9_400,
            tags: ["clock", "grid", "words"],
            createdAt: Date().addingTimeInterval(-86400 * 220),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false,
            template: "word"
        ),
        
        Screensaver(
            id: stableUUID("word-clock-typewriter"),
            name: "Typewriter Clock",
            description: "A super simple word clock with typewriter animation.",
            category: .clocks,
            thumbnailURL: "typewriter_clock",
            downloadURL: "https://github.com/wordclock",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 6_800,
            tags: ["clock", "typewriter", "words"],
            createdAt: Date().addingTimeInterval(-86400 * 160),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false,
            template: "word"
        ),
        
        Screensaver(
            id: stableUUID("simple-clock"),
            name: "Simple Clock",
            description: "A classic analogue clock with multiple interchange skins.",
            category: .clocks,
            thumbnailURL: "simple_clock",
            downloadURL: "https://github.com/simpleclock",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 15_300,
            tags: ["clock", "analogue", "skins"],
            createdAt: Date().addingTimeInterval(-86400 * 280),
            rank: nil,
            resolution: "Retina",
            fileSize: "3MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("colorclock"),
            name: "ColorClock",
            description: "Displays a solid color corresponding to current time hex.",
            category: .clocks,
            thumbnailURL: "colorclock",
            downloadURL: "https://github.com/colorclock",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 22_100,
            tags: ["clock", "color", "hex"],
            createdAt: Date().addingTimeInterval(-86400 * 310),
            rank: nil,
            resolution: "Dynamic",
            fileSize: "1MB",
            isNew: false,
            template: "color"
        ),
        
        Screensaver(
            id: stableUUID("screenmazer"),
            name: "ScreenMazer",
            description: "Builds and solves a maze while showing the time.",
            category: .clocks,
            thumbnailURL: "screenmazer",
            downloadURL: "https://github.com/screenmazer",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 11_600,
            tags: ["clock", "maze", "generative"],
            createdAt: Date().addingTimeInterval(-86400 * 140),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: true,
            template: "nature"
        ),
        
        Screensaver(
            id: stableUUID("evangelion-clock"),
            name: "Evangelion Clock",
            description: "Digital clock inspired by Neon Genesis Evangelion interfaces.",
            category: .clocks,
            thumbnailURL: "evangelion_clock",
            downloadURL: "https://github.com/evangelionclock",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 41_200,
            tags: ["clock", "anime", "sci-fi"],
            createdAt: Date().addingTimeInterval(-86400 * 90),
            rank: 2,
            resolution: "4K",
            fileSize: "6MB",
            isNew: false,
            template: "sci-fi"
        ),
        
        Screensaver(
            id: stableUUID("predator-clock"),
            name: "Predator",
            description: "Alien HUD style clock from the Predator franchise.",
            category: .clocks,
            thumbnailURL: "predator",
            downloadURL: "https://github.com/predatorclock",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 14_800,
            tags: ["clock", "predator", "sci-fi"],
            createdAt: Date().addingTimeInterval(-86400 * 170),
            rank: nil,
            resolution: "Retina",
            fileSize: "4MB",
            isNew: false,
            template: "sci-fi"
        ),
        
        Screensaver(
            id: stableUUID("death-counter"),
            name: "Death Counter",
            description: "Estimated countdown to your expiration.",
            category: .clocks,
            thumbnailURL: "death_counter",
            downloadURL: "https://github.com/deathcounter",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 7_300,
            tags: ["clock", "countdown", "dark"],
            createdAt: Date().addingTimeInterval(-86400 * 120),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("minimalclock"),
            name: "MinimalClock",
            description: "Elegant typography on a dark canvas.",
            category: .clocks,
            thumbnailURL: "minimal_clock",
            downloadURL: "https://github.com/mattiarossini/MinimalClock",
            isPremium: false,
            price: nil,
            author: "Mattia Rossini",
            downloadCount: 52_100,
            tags: ["clock", "minimal", "dark"],
            createdAt: Date().addingTimeInterval(-86400 * 60),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("multiclock"),
            name: "MultiClock",
            description: "Time and animations using 24 individual clocks.",
            category: .clocks,
            thumbnailURL: "multiclock",
            downloadURL: "https://github.com/multiclock",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 16_900,
            tags: ["clock", "grid", "analogue"],
            createdAt: Date().addingTimeInterval(-86400 * 40),
            rank: nil,
            resolution: "4K",
            fileSize: "3MB",
            isNew: true,
            template: "matrix"
        ),
        
        Screensaver(
            id: stableUUID("flip-clock-screensaver"),
            name: "Flip Clock Screensaver",
            description: "Polished flip clock with screen dimming.",
            category: .clocks,
            thumbnailURL: "flip_clock_ss",
            downloadURL: "https://github.com/flipclockss",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 10_500,
            tags: ["clock", "flip", "dim"],
            createdAt: Date().addingTimeInterval(-86400 * 30),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: true,
            template: "flip"
        ),
        
        Screensaver(
            id: stableUUID("digital-electric"),
            name: "Digital Electric",
            description: "Vintage alarm clock style with glowing led segments.",
            category: .clocks,
            thumbnailURL: "digital_electric",
            downloadURL: "https://github.com/digitalelectric",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 5_600,
            tags: ["clock", "retro", "led"],
            createdAt: Date().addingTimeInterval(-86400 * 75),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false,
            template: "minimal"
        ),
        
        // ── APPLE INSPIRED ──
        
        Screensaver(
            id: stableUUID("aerial"),
            name: "Aerial",
            description: "Apple TV aerial screensavers for your Mac.",
            category: .appleInspired,
            thumbnailURL: "aerial",
            downloadURL: "https://github.com/JohnCoates/Aerial",
            isPremium: false,
            price: nil,
            author: "John Coates",
            downloadCount: 245_000,
            tags: ["aerial", "apple", "drone"],
            createdAt: Date().addingTimeInterval(-86400 * 400),
            rank: 1,
            resolution: "4K@60",
            fileSize: "Dynamic",
            isNew: false,
            template: "nature"
        ),
        
        Screensaver(
            id: stableUUID("apple-watch"),
            name: "Apple Watch",
            description: "Faithfully recreates Apple Watch faces.",
            category: .appleInspired,
            thumbnailURL: "apple_watch",
            downloadURL: "https://github.com/applewatch",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 28_300,
            tags: ["apple", "watch"],
            createdAt: Date().addingTimeInterval(-86400 * 260),
            rank: nil,
            resolution: "Retina",
            fileSize: "8MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("brooklyn"),
            name: "Brooklyn",
            description: "Inspired by Apple's October 30, 2018 event.",
            category: .appleInspired,
            thumbnailURL: "brooklyn",
            downloadURL: "https://github.com/pedrommcarrasco/Brooklyn",
            isPremium: false,
            price: nil,
            author: "Pedro Carrasco",
            downloadCount: 67_800,
            tags: ["apple", "logo", "art"],
            createdAt: Date().addingTimeInterval(-86400 * 210),
            rank: 2,
            resolution: "4K",
            fileSize: "15MB",
            isNew: false,
            template: "nature"
        ),
        
        Screensaver(
            id: stableUUID("ios-lockscreen"),
            name: "iOS Lockscreen",
            description: "Elegant iOS lockscreen right on your Mac.",
            category: .appleInspired,
            thumbnailURL: "ios_lockscreen",
            downloadURL: "https://github.com/ioslockscreen",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 19_500,
            tags: ["apple", "ios", "lockscreen"],
            createdAt: Date().addingTimeInterval(-86400 * 190),
            rank: nil,
            resolution: "Retina",
            fileSize: "5MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("october-30"),
            name: "October 30",
            description: "Smoothly transitions through 371 Apple logo variants.",
            category: .appleInspired,
            thumbnailURL: "october_30",
            downloadURL: "https://github.com/lekevicius/october30",
            isPremium: false,
            price: nil,
            author: "Jonas Lekevicius",
            downloadCount: 54_200,
            tags: ["apple", "logo", "art"],
            createdAt: Date().addingTimeInterval(-86400 * 200),
            rank: 3,
            resolution: "4K",
            fileSize: "42MB",
            isNew: false,
            template: "nature"
        ),
        
        Screensaver(
            id: stableUUID("fruit"),
            name: "Fruit",
            description: "Animated vintage rainbow Apple logo.",
            category: .appleInspired,
            thumbnailURL: "fruit",
            downloadURL: "https://github.com/fruit",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 13_700,
            tags: ["apple", "retro", "logo"],
            createdAt: Date().addingTimeInterval(-86400 * 150),
            rank: nil,
            resolution: "Retina",
            fileSize: "4MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("swiftbubble"),
            name: "SwiftBubble",
            description: "Soap bubble screensaver from MacBook promotional videos.",
            category: .appleInspired,
            thumbnailURL: "swiftbubble",
            downloadURL: "https://github.com/nicklama/swiftbubble",
            isPremium: false,
            price: nil,
            author: "Nick Lama",
            downloadCount: 20_400,
            tags: ["apple", "bubble", "promo"],
            createdAt: Date().addingTimeInterval(-86400 * 130),
            rank: nil,
            resolution: "4K",
            fileSize: "6MB",
            isNew: false,
            template: "nature"
        ),
        
        // ── RETRO ──
        
        Screensaver(
            id: stableUUID("pongsaver"),
            name: "PongSaver",
            description: "Keeps time using a scoring game of Pong.",
            category: .retro,
            thumbnailURL: "pongsaver",
            downloadURL: "https://github.com/pongsaver",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 35_800,
            tags: ["retro", "pong", "clock"],
            createdAt: Date().addingTimeInterval(-86400 * 350),
            rank: 1,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false,
            template: "retro"
        ),
        
        Screensaver(
            id: stableUUID("textify-me"),
            name: "Textify Me",
            description: "Live ASCII text art from your camera stream.",
            category: .retro,
            thumbnailURL: "textify_me",
            downloadURL: "https://textify.app",
            isPremium: true,
            price: 0.99,
            author: "Textify Studio",
            downloadCount: 8_900,
            tags: ["retro", "camera", "ascii"],
            createdAt: Date().addingTimeInterval(-86400 * 270),
            rank: nil,
            resolution: "Dynamic",
            fileSize: "8MB",
            isNew: false,
            template: "retro"
        ),
        
        Screensaver(
            id: stableUUID("start-now"),
            name: "Start Now",
            description: "Motivational quotes with beautiful typography.",
            category: .retro,
            thumbnailURL: "start_now",
            downloadURL: "https://github.com/startnow",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 11_200,
            tags: ["quotes", "motivation"],
            createdAt: Date().addingTimeInterval(-86400 * 230),
            rank: nil,
            resolution: "Retina",
            fileSize: "3MB",
            isNew: false,
            template: "minimal"
        ),
        
        // ── SCI-FI ──
        
        Screensaver(
            id: stableUUID("github-matrix"),
            name: "GitHub Matrix",
            description: "Latest commits in a green Matrix-style rain.",
            category: .sciFi,
            thumbnailURL: "github_matrix",
            downloadURL: "https://github.com/winterbe/github-matrix-screensaver",
            isPremium: false,
            price: nil,
            author: "Benjamin Winterberg",
            downloadCount: 48_300,
            tags: ["matrix", "github", "code"],
            createdAt: Date().addingTimeInterval(-86400 * 320),
            rank: 1,
            resolution: "4K",
            fileSize: "5MB",
            isNew: false,
            template: "matrix"
        ),
        
        Screensaver(
            id: stableUUID("starwars-scroll"),
            name: "Star Wars Scroll",
            description: "The iconic opening title crawl from the movies.",
            category: .sciFi,
            thumbnailURL: "starwars_scroll",
            downloadURL: "https://github.com/starwarsscroll",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 31_600,
            tags: ["star-wars", "scroll", "movie"],
            createdAt: Date().addingTimeInterval(-86400 * 290),
            rank: 2,
            resolution: "4K",
            fileSize: "4MB",
            isNew: false,
            template: "sci-fi"
        ),
        
        Screensaver(
            id: stableUUID("matrix"),
            name: "Matrix",
            description: "Classic green digital rain for your screen.",
            category: .sciFi,
            thumbnailURL: "matrix",
            downloadURL: "https://github.com/matrix",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 56_700,
            tags: ["matrix", "rain", "hacker"],
            createdAt: Date().addingTimeInterval(-86400 * 380),
            rank: 3,
            resolution: "4K",
            fileSize: "3MB",
            isNew: false,
            template: "matrix"
        ),
        
        // ── OTHER CATEGORIES (Truncated for brevity, following same pattern) ──
        
        Screensaver(
            id: stableUUID("speed-run"),
            name: "Speed Run",
            description: "Watch live gaming skill and precision.",
            category: .videoGame,
            thumbnailURL: "speed_run",
            downloadURL: "https://github.com/speedrun",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 5_400,
            tags: ["gaming", "video"],
            createdAt: Date().addingTimeInterval(-86400 * 240),
            rank: 1,
            resolution: "1080p",
            fileSize: "Dynamic",
            isNew: false,
            template: "nature"
        ),
        
        Screensaver(
            id: stableUUID("aquarium"),
            name: "Aquarium",
            description: "Serene underwater world video.",
            category: .aquarium,
            thumbnailURL: "aquarium",
            downloadURL: "https://github.com/aquarium",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 21_300,
            tags: ["aquarium", "fish"],
            createdAt: Date().addingTimeInterval(-86400 * 260),
            rank: 1,
            resolution: "4K",
            fileSize: "Dynamic",
            isNew: false,
            template: "nature"
        ),
        
        Screensaver(
            id: stableUUID("developer-excuses"),
            name: "Developer Excuses",
            description: "Displays random classic dev excuses.",
            category: .developer,
            thumbnailURL: "dev_excuses",
            downloadURL: "https://github.com/developerexcuses",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 27_800,
            tags: ["developer", "humor"],
            createdAt: Date().addingTimeInterval(-86400 * 310),
            rank: 1,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("macos-kernel-panic"),
            name: "macOS Kernel Panic",
            description: "Harmless emulation of a system crash.",
            category: .developer,
            thumbnailURL: "kernel_panic",
            downloadURL: "https://github.com/dbunn/osx-kernelpanic",
            isPremium: false,
            price: nil,
            author: "Daniel Bunn",
            downloadCount: 39_400,
            tags: ["developer", "prank"],
            createdAt: Date().addingTimeInterval(-86400 * 330),
            rank: 2,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false,
            template: "sci-fi"
        ),
        
        Screensaver(
            id: stableUUID("windows-kernel-panic"),
            name: "Windows BSOD",
            description: "The Blue Screen of Death, faithfully recreated.",
            category: .developer,
            thumbnailURL: "bsod",
            downloadURL: "https://github.com/windows-bsod",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 33_100,
            tags: ["developer", "prank", "windows"],
            createdAt: Date().addingTimeInterval(-86400 * 340),
            rank: 3,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("octoscreen"),
            name: "Octoscreen",
            description: "GitHub's Octicons floating across your screen.",
            category: .developer,
            thumbnailURL: "octoscreen",
            downloadURL: "https://github.com/octoscreen",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 7_200,
            tags: ["developer", "github"],
            createdAt: Date().addingTimeInterval(-86400 * 280),
            rank: nil,
            resolution: "Retina",
            fileSize: "3MB",
            isNew: false,
            template: "generative"
        ),
        
        Screensaver(
            id: stableUUID("electric-sheep"),
            name: "Electric Sheep",
            description: "Infinite, evolving artwork of fractal sheep.",
            category: .graphics,
            thumbnailURL: "electric_sheep",
            downloadURL: "https://electricsheep.org",
            isPremium: false,
            price: nil,
            author: "Scott Draves",
            downloadCount: 62_500,
            tags: ["fractal", "generative"],
            createdAt: Date().addingTimeInterval(-86400 * 400),
            rank: 1,
            resolution: "4K",
            fileSize: "Dynamic",
            isNew: false,
            template: "generative"
        ),
        
        Screensaver(
            id: stableUUID("screensson"),
            name: "Screensson",
            description: "Unique patterns from stacking vector stencils.",
            category: .graphics,
            thumbnailURL: "screensson",
            downloadURL: "https://screensson.com",
            isPremium: false,
            price: nil,
            author: "Screensson",
            downloadCount: 9_800,
            tags: ["generative", "art"],
            createdAt: Date().addingTimeInterval(-86400 * 270),
            rank: nil,
            resolution: "Retina",
            fileSize: "5MB",
            isNew: false,
            template: "generative"
        ),
        
        Screensaver(
            id: stableUUID("emoji-saver"),
            name: "Emoji Saver",
            description: "Animates emojis across your screen.",
            category: .graphics,
            thumbnailURL: "emoji_saver",
            downloadURL: "https://emojisaver.com",
            isPremium: true,
            price: 3.00,
            author: "Emoji Saver Studio",
            downloadCount: 14_700,
            tags: ["emoji", "animation"],
            createdAt: Date().addingTimeInterval(-86400 * 200),
            rank: nil,
            resolution: "Retina",
            fileSize: "12MB",
            isNew: false,
            template: "generative"
        ),
        
        Screensaver(
            id: stableUUID("life-saver"),
            name: "Life Saver",
            description: "Beautifully rendered abstract Game of Life.",
            category: .graphics,
            thumbnailURL: "life_saver",
            downloadURL: "https://www.yourlifesaver.com",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 24_600,
            tags: ["generative", "abstract"],
            createdAt: Date().addingTimeInterval(-86400 * 180),
            rank: 2,
            resolution: "4K",
            fileSize: "4MB",
            isNew: false,
            template: "generative"
        ),
        
        Screensaver(
            id: stableUUID("electropaintosx"),
            name: "ElectropaintOSX",
            description: "Faithful port of the legendary SGI screensaver.",
            category: .graphics,
            thumbnailURL: "electropaint",
            downloadURL: "https://github.com/electropaint",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 11_200,
            tags: ["graphics", "retro"],
            createdAt: Date().addingTimeInterval(-86400 * 160),
            rank: nil,
            resolution: "4K",
            fileSize: "3MB",
            isNew: false,
            template: "sci-fi"
        ),
        
        Screensaver(
            id: stableUUID("ealain"),
            name: "Ealain",
            description: "Abstract art generated by Stable Diffusion.",
            category: .graphics,
            thumbnailURL: "ealain",
            downloadURL: "https://github.com/amiantos/ealain",
            isPremium: false,
            price: nil,
            author: "Brad Root",
            downloadCount: 18_900,
            tags: ["ai", "generative"],
            createdAt: Date().addingTimeInterval(-86400 * 25),
            rank: 3,
            resolution: "4K",
            fileSize: "Dynamic",
            isNew: true,
            template: "generative"
        ),
        
        Screensaver(
            id: stableUUID("google-trends"),
            name: "Google Trends",
            description: "Displays latest hot searches in real time.",
            category: .other,
            thumbnailURL: "google_trends",
            downloadURL: "https://github.com/googletrends",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 8_700,
            tags: ["google", "trends"],
            createdAt: Date().addingTimeInterval(-86400 * 100),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: true,
            template: "word"
        ),
        
        Screensaver(
            id: stableUUID("last-statement"),
            name: "Last Statement",
            description: "Solemn, typographic presentation of final words.",
            category: .other,
            thumbnailURL: "last_statement",
            downloadURL: "https://github.com/laststatement",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 4_600,
            tags: ["typography", "sobering"],
            createdAt: Date().addingTimeInterval(-86400 * 110),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false,
            template: "minimal"
        ),
        
        Screensaver(
            id: stableUUID("macos-live"),
            name: "macOS Live Screensaver",
            description: "Plays live video streams from YouTube sources.",
            category: .other,
            thumbnailURL: "macos_live",
            downloadURL: "https://github.com/macoslive",
            isPremium: false,
            price: nil,
            author: "Community",
            downloadCount: 15_200,
            tags: ["live", "video"],
            createdAt: Date().addingTimeInterval(-86400 * 50),
            rank: nil,
            resolution: "Dynamic",
            fileSize: "Dynamic",
            isNew: true,
            template: "nature"
        ),
    ]
}
