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
    
    // MARK: - Singleton
    
    static let shared = APIManager()
    
    private init() {}
    
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
    
    /// Creates a stable UUID from a string seed, so mock IDs stay consistent across launches.
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
    // Source: github.com/agarrharr/awesome-macos-screensavers
    
    private static let mockScreensavers: [Screensaver] = [
        
        // ╔══════════════════════════════════════════════════╗
        // ║                   CLOCKS (16)                    ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("fliqlo"),
            name: "Fliqlo",
            description: "A retro-style flip clock screensaver with elegant mechanical card-flip animations. A timeless classic loved by minimalists worldwide.",
            category: .clocks,
            thumbnailURL: "fliqlo",
            downloadURL: "https://fliqlo.com",
            isPremium: false,
            price: nil,
            author: "Yuji Adachi",
            rating: 4.9,
            downloadCount: 184_500,
            tags: ["clock", "flip", "retro", "minimal", "classic"],
            createdAt: Date().addingTimeInterval(-86400 * 365),
            rank: 1,
            resolution: "Retina",
            fileSize: "3MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("today"),
            name: "Today",
            description: "Time or date displayed in a minimal style inspired by On Kawara's iconic 'Today Series' paintings. Art meets functionality.",
            category: .clocks,
            thumbnailURL: "today",
            downloadURL: "https://github.com/jacklatimer/today",
            isPremium: false,
            price: nil,
            author: "Jack Latimer",
            rating: 4.3,
            downloadCount: 12_400,
            tags: ["clock", "art", "minimal", "painting", "date"],
            createdAt: Date().addingTimeInterval(-86400 * 200),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("word-clock-circular"),
            name: "Word Clock",
            description: "A beautifully crafted clock made entirely of words. Switches between a circular layout and a flowing paragraph layout.",
            category: .clocks,
            thumbnailURL: "word_clock",
            downloadURL: "https://www.simonheys.com/wordclock/",
            isPremium: false,
            price: nil,
            author: "Simon Heys",
            rating: 4.6,
            downloadCount: 34_200,
            tags: ["clock", "words", "typography", "circular", "elegant"],
            createdAt: Date().addingTimeInterval(-86400 * 300),
            rank: 3,
            resolution: "Retina",
            fileSize: "4MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("fractal-clock"),
            name: "Fractal Clock",
            description: "A mesmerizing clock that generates evolving fractal tree patterns radiating from its hands as time passes.",
            category: .clocks,
            thumbnailURL: "fractal_clock",
            downloadURL: "https://github.com/fractalclock",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.4,
            downloadCount: 18_700,
            tags: ["clock", "fractal", "generative", "math", "tree"],
            createdAt: Date().addingTimeInterval(-86400 * 250),
            rank: nil,
            resolution: "4K",
            fileSize: "5MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("epoch-flip-clock"),
            name: "Epoch Flip Clock",
            description: "Unix epoch time displayed as a flip clock. Perfect for developers who think in timestamps.",
            category: .clocks,
            thumbnailURL: "epoch_flip",
            downloadURL: "https://github.com/epochflipclock",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.1,
            downloadCount: 8_200,
            tags: ["clock", "unix", "epoch", "developer", "flip"],
            createdAt: Date().addingTimeInterval(-86400 * 180),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("grid-clock"),
            name: "Grid Clock",
            description: "Twelve-hour time expressed entirely in English words arranged in a clean, readable grid layout.",
            category: .clocks,
            thumbnailURL: "grid_clock",
            downloadURL: "https://github.com/gridclock",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.2,
            downloadCount: 9_400,
            tags: ["clock", "grid", "words", "typography", "minimal"],
            createdAt: Date().addingTimeInterval(-86400 * 220),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("word-clock-typewriter"),
            name: "Typewriter Clock",
            description: "A super simple word clock that types out the current time letter by letter, as if your computer is a typewriter.",
            category: .clocks,
            thumbnailURL: "typewriter_clock",
            downloadURL: "https://github.com/wordclock",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.0,
            downloadCount: 6_800,
            tags: ["clock", "typewriter", "words", "animation", "simple"],
            createdAt: Date().addingTimeInterval(-86400 * 160),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("simple-clock"),
            name: "Simple Clock",
            description: "A classic analogue clock screensaver with multiple interchangeable face skins. Clean, functional, and timeless.",
            category: .clocks,
            thumbnailURL: "simple_clock",
            downloadURL: "https://github.com/simpleclock",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.3,
            downloadCount: 15_300,
            tags: ["clock", "analogue", "skins", "classic", "simple"],
            createdAt: Date().addingTimeInterval(-86400 * 280),
            rank: nil,
            resolution: "Retina",
            fileSize: "3MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("colorclock"),
            name: "ColorClock",
            description: "Displays a solid color that corresponds to the current time — the hex color value changes every second.",
            category: .clocks,
            thumbnailURL: "colorclock",
            downloadURL: "https://github.com/colorclock",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.5,
            downloadCount: 22_100,
            tags: ["clock", "color", "hex", "minimal", "ambient"],
            createdAt: Date().addingTimeInterval(-86400 * 310),
            rank: nil,
            resolution: "Dynamic",
            fileSize: "1MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("screenmazer"),
            name: "ScreenMazer",
            description: "Continuously builds and then solves a randomly-generated maze while displaying the current time. Hypnotic and functional.",
            category: .clocks,
            thumbnailURL: "screenmazer",
            downloadURL: "https://github.com/screenmazer",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.4,
            downloadCount: 11_600,
            tags: ["clock", "maze", "puzzle", "generative", "animation"],
            createdAt: Date().addingTimeInterval(-86400 * 140),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: true
        ),
        
        Screensaver(
            id: stableUUID("evangelion-clock"),
            name: "Evangelion Clock",
            description: "A digital clock screensaver inspired by the graphical interfaces from Neon Genesis Evangelion. Warning: may trigger Third Impact.",
            category: .clocks,
            thumbnailURL: "evangelion_clock",
            downloadURL: "https://github.com/evangelionclock",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.7,
            downloadCount: 41_200,
            tags: ["clock", "anime", "evangelion", "sci-fi", "neon"],
            createdAt: Date().addingTimeInterval(-86400 * 90),
            rank: 2,
            resolution: "4K",
            fileSize: "6MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("predator-clock"),
            name: "Predator",
            description: "A clock screensaver inspired by the alien script and HUD elements from the Predator franchise. See time like a Yautja.",
            category: .clocks,
            thumbnailURL: "predator",
            downloadURL: "https://github.com/predatorclock",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.3,
            downloadCount: 14_800,
            tags: ["clock", "predator", "alien", "sci-fi", "movie"],
            createdAt: Date().addingTimeInterval(-86400 * 170),
            rank: nil,
            resolution: "Retina",
            fileSize: "4MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("death-counter"),
            name: "Death Counter",
            description: "A sobering counter screensaver that counts down the estimated time to your expiration. Memento mori for your Mac.",
            category: .clocks,
            thumbnailURL: "death_counter",
            downloadURL: "https://github.com/deathcounter",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 3.9,
            downloadCount: 7_300,
            tags: ["clock", "countdown", "existential", "dark", "mortality"],
            createdAt: Date().addingTimeInterval(-86400 * 120),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("minimalclock"),
            name: "MinimalClock",
            description: "The most elegant minimal clock screensaver for macOS. Pure typography on a dark canvas. Nothing more, nothing less.",
            category: .clocks,
            thumbnailURL: "minimal_clock",
            downloadURL: "https://github.com/mattiarossini/MinimalClock",
            isPremium: false,
            price: nil,
            author: "Mattia Rossini",
            rating: 4.8,
            downloadCount: 52_100,
            tags: ["clock", "minimal", "typography", "dark", "elegant"],
            createdAt: Date().addingTimeInterval(-86400 * 60),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("multiclock"),
            name: "MultiClock",
            description: "Displays the current time and animations using 24 individual analogue clocks arranged in a grid. A symphony of rotating hands.",
            category: .clocks,
            thumbnailURL: "multiclock",
            downloadURL: "https://github.com/multiclock",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.5,
            downloadCount: 16_900,
            tags: ["clock", "grid", "analogue", "animation", "multi"],
            createdAt: Date().addingTimeInterval(-86400 * 40),
            rank: nil,
            resolution: "4K",
            fileSize: "3MB",
            isNew: true
        ),
        
        Screensaver(
            id: stableUUID("flip-clock-screensaver"),
            name: "Flip Clock Screensaver",
            description: "A polished flip clock screensaver with automatic screen dimming capability. Configurable dim delay and brightness.",
            category: .clocks,
            thumbnailURL: "flip_clock_ss",
            downloadURL: "https://github.com/flipclockss",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.2,
            downloadCount: 10_500,
            tags: ["clock", "flip", "dim", "ambient", "configurable"],
            createdAt: Date().addingTimeInterval(-86400 * 30),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: true
        ),
        
        Screensaver(
            id: stableUUID("digital-electric"),
            name: "Digital Electric",
            description: "A beautifully nostalgic screensaver inspired by old-fashioned alarm clocks with glowing LED digit segments.",
            category: .clocks,
            thumbnailURL: "digital_electric",
            downloadURL: "https://github.com/digitalelectric",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.1,
            downloadCount: 5_600,
            tags: ["clock", "retro", "LED", "vintage", "alarm"],
            createdAt: Date().addingTimeInterval(-86400 * 75),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false
        ),
        
        // ╔══════════════════════════════════════════════════╗
        // ║              APPLE INSPIRED (7)                  ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("aerial"),
            name: "Aerial",
            description: "The iconic Apple TV aerial screensaver brought to your Mac. Stunning drone footage of cities, landscapes, and underwater scenes from around the globe.",
            category: .appleInspired,
            thumbnailURL: "aerial",
            downloadURL: "https://github.com/JohnCoates/Aerial",
            isPremium: false,
            price: nil,
            author: "John Coates",
            rating: 4.9,
            downloadCount: 245_000,
            tags: ["aerial", "apple", "drone", "4K", "nature", "city"],
            createdAt: Date().addingTimeInterval(-86400 * 400),
            rank: 1,
            resolution: "4K@60",
            fileSize: "Dynamic",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("apple-watch"),
            name: "Apple Watch",
            description: "A screensaver that faithfully recreates the Apple Watch face on your Mac display. Multiple watch face styles included.",
            category: .appleInspired,
            thumbnailURL: "apple_watch",
            downloadURL: "https://github.com/applewatch",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.4,
            downloadCount: 28_300,
            tags: ["apple", "watch", "watchface", "minimal", "luxury"],
            createdAt: Date().addingTimeInterval(-86400 * 260),
            rank: nil,
            resolution: "Retina",
            fileSize: "8MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("brooklyn"),
            name: "Brooklyn",
            description: "Inspired by Apple's October 30, 2018 event. Smoothly morphing Apple logos in stunning artistic styles.",
            category: .appleInspired,
            thumbnailURL: "brooklyn",
            downloadURL: "https://github.com/pedrommcarrasco/Brooklyn",
            isPremium: false,
            price: nil,
            author: "Pedro Carrasco",
            rating: 4.7,
            downloadCount: 67_800,
            tags: ["apple", "logo", "art", "event", "morphing"],
            createdAt: Date().addingTimeInterval(-86400 * 210),
            rank: 2,
            resolution: "4K",
            fileSize: "15MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("ios-lockscreen"),
            name: "iOS Lockscreen",
            description: "Experience the elegant iOS lockscreen right on your Mac. Complete with time display, date, and familiar blur effects.",
            category: .appleInspired,
            thumbnailURL: "ios_lockscreen",
            downloadURL: "https://github.com/ioslockscreen",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.2,
            downloadCount: 19_500,
            tags: ["apple", "iOS", "lockscreen", "iPhone", "blur"],
            createdAt: Date().addingTimeInterval(-86400 * 190),
            rank: nil,
            resolution: "Retina",
            fileSize: "5MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("october-30"),
            name: "October 30",
            description: "Smoothly transitions between 371 unique Apple logo variations from the 2018 iPad Pro event. A museum of Apple design in motion.",
            category: .appleInspired,
            thumbnailURL: "october_30",
            downloadURL: "https://github.com/lekevicius/october30",
            isPremium: false,
            price: nil,
            author: "Jonas Lekevicius",
            rating: 4.6,
            downloadCount: 54_200,
            tags: ["apple", "logo", "art", "371", "event", "iPad"],
            createdAt: Date().addingTimeInterval(-86400 * 200),
            rank: 3,
            resolution: "4K",
            fileSize: "42MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("fruit"),
            name: "Fruit",
            description: "The vintage rainbow Apple logo, lovingly animated with smooth transitions and retro charm. A nod to Apple's colorful heritage.",
            category: .appleInspired,
            thumbnailURL: "fruit",
            downloadURL: "https://github.com/fruit",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.3,
            downloadCount: 13_700,
            tags: ["apple", "retro", "rainbow", "logo", "vintage"],
            createdAt: Date().addingTimeInterval(-86400 * 150),
            rank: nil,
            resolution: "Retina",
            fileSize: "4MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("swiftbubble"),
            name: "SwiftBubble",
            description: "A faithful recreation of the mesmerizing soap bubble screensaver from Apple's MacBook 12-inch promotional videos. Pure iridescent beauty.",
            category: .appleInspired,
            thumbnailURL: "swiftbubble",
            downloadURL: "https://github.com/nicklama/swiftbubble",
            isPremium: false,
            price: nil,
            author: "Nick Lama",
            rating: 4.5,
            downloadCount: 20_400,
            tags: ["apple", "bubble", "macbook", "iridescent", "promo"],
            createdAt: Date().addingTimeInterval(-86400 * 130),
            rank: nil,
            resolution: "4K",
            fileSize: "6MB",
            isNew: false
        ),
        
        // ╔══════════════════════════════════════════════════╗
        // ║                  RETRO (3)                       ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("pongsaver"),
            name: "PongSaver",
            description: "A screensaver that keeps time using a game of Pong. The left player wins once an hour, the right player wins once a minute. Genius.",
            category: .retro,
            thumbnailURL: "pongsaver",
            downloadURL: "https://github.com/pongsaver",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.6,
            downloadCount: 35_800,
            tags: ["retro", "pong", "game", "clock", "arcade", "classic"],
            createdAt: Date().addingTimeInterval(-86400 * 350),
            rank: 1,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("textify-me"),
            name: "Textify Me",
            description: "An interactive screensaver that transforms everything in front of your camera into live ASCII text art. Mesmerizing in real-time.",
            category: .retro,
            thumbnailURL: "textify_me",
            downloadURL: "https://textify.app",
            isPremium: true,
            price: 0.99,
            author: "Textify Studio",
            rating: 4.3,
            downloadCount: 8_900,
            tags: ["retro", "camera", "text", "ASCII", "interactive", "live"],
            createdAt: Date().addingTimeInterval(-86400 * 270),
            rank: nil,
            resolution: "Dynamic",
            fileSize: "8MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("start-now"),
            name: "Start Now",
            description: "Draw inspiration from great minds every time you wake up your Mac. Displays motivational quotes with beautiful typography.",
            category: .retro,
            thumbnailURL: "start_now",
            downloadURL: "https://github.com/startnow",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.1,
            downloadCount: 11_200,
            tags: ["quotes", "motivation", "typography", "inspirational"],
            createdAt: Date().addingTimeInterval(-86400 * 230),
            rank: nil,
            resolution: "Retina",
            fileSize: "3MB",
            isNew: false
        ),
        
        // ╔══════════════════════════════════════════════════╗
        // ║                 SCI-FI (3)                       ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("github-matrix"),
            name: "GitHub Matrix",
            description: "The latest commits from GitHub repositories visualized in a stunning Matrix-style cascading animation. Watch the code rain.",
            category: .sciFi,
            thumbnailURL: "github_matrix",
            downloadURL: "https://github.com/winterbe/github-matrix-screensaver",
            isPremium: false,
            price: nil,
            author: "Benjamin Winterberg",
            rating: 4.7,
            downloadCount: 48_300,
            tags: ["matrix", "github", "code", "animation", "green", "sci-fi"],
            createdAt: Date().addingTimeInterval(-86400 * 320),
            rank: 1,
            resolution: "4K",
            fileSize: "5MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("starwars-scroll"),
            name: "Star Wars Scroll",
            description: "Recreates the iconic opening title crawl from Star Wars. Features the text scrolls from the original six films.",
            category: .sciFi,
            thumbnailURL: "starwars_scroll",
            downloadURL: "https://github.com/starwarsscroll",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.5,
            downloadCount: 31_600,
            tags: ["star-wars", "scroll", "movie", "sci-fi", "text", "crawl"],
            createdAt: Date().addingTimeInterval(-86400 * 290),
            rank: 2,
            resolution: "4K",
            fileSize: "4MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("matrix"),
            name: "Matrix",
            description: "The classic Matrix digital rain. Green katakana characters cascade down your screen in this faithful recreation of the iconic visual.",
            category: .sciFi,
            thumbnailURL: "matrix",
            downloadURL: "https://github.com/matrix",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.6,
            downloadCount: 56_700,
            tags: ["matrix", "rain", "green", "sci-fi", "katakana", "hacker"],
            createdAt: Date().addingTimeInterval(-86400 * 380),
            rank: 3,
            resolution: "4K",
            fileSize: "3MB",
            isNew: false
        ),
        
        // ╔══════════════════════════════════════════════════╗
        // ║               VIDEO GAME (1)                     ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("speed-run"),
            name: "Speed Run",
            description: "Watch videos of gamers completing speed runs of classic video games. An ever-changing showcase of gaming skill and precision.",
            category: .videoGame,
            thumbnailURL: "speed_run",
            downloadURL: "https://github.com/speedrun",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.0,
            downloadCount: 5_400,
            tags: ["gaming", "speedrun", "video", "retro", "competition"],
            createdAt: Date().addingTimeInterval(-86400 * 240),
            rank: 1,
            resolution: "1080p",
            fileSize: "Dynamic",
            isNew: false
        ),
        
        // ╔══════════════════════════════════════════════════╗
        // ║                AQUARIUM (1)                      ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("aquarium"),
            name: "Aquarium",
            description: "Transform your Mac into a serene underwater world. High-quality video of real aquariums with tropical fish and coral reefs.",
            category: .aquarium,
            thumbnailURL: "aquarium",
            downloadURL: "https://github.com/aquarium",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.4,
            downloadCount: 21_300,
            tags: ["aquarium", "fish", "underwater", "nature", "relaxing", "coral"],
            createdAt: Date().addingTimeInterval(-86400 * 260),
            rank: 1,
            resolution: "4K",
            fileSize: "Dynamic",
            isNew: false
        ),
        
        // ╔══════════════════════════════════════════════════╗
        // ║               DEVELOPER (4)                      ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("developer-excuses"),
            name: "Developer Excuses",
            description: "Displays random developer excuses from developerexcuses.com. 'It works on my machine' and 300+ other classics, beautifully rendered.",
            category: .developer,
            thumbnailURL: "dev_excuses",
            downloadURL: "https://github.com/developerexcuses",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.5,
            downloadCount: 27_800,
            tags: ["developer", "humor", "quotes", "programming", "excuses"],
            createdAt: Date().addingTimeInterval(-86400 * 310),
            rank: 1,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("macos-kernel-panic"),
            name: "macOS Kernel Panic",
            description: "A harmless screensaver that faithfully emulates the experience of a macOS kernel panic. Perfect for pranking your coworkers.",
            category: .developer,
            thumbnailURL: "kernel_panic",
            downloadURL: "https://github.com/dbunn/osx-kernelpanic",
            isPremium: false,
            price: nil,
            author: "Daniel Bunn",
            rating: 4.6,
            downloadCount: 39_400,
            tags: ["developer", "prank", "kernel", "panic", "system", "macOS"],
            createdAt: Date().addingTimeInterval(-86400 * 330),
            rank: 2,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("windows-kernel-panic"),
            name: "Windows BSOD",
            description: "The Blue Screen of Death, faithfully recreated as a macOS screensaver. A harmless homage to Windows' most infamous screen.",
            category: .developer,
            thumbnailURL: "bsod",
            downloadURL: "https://github.com/windows-bsod",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.4,
            downloadCount: 33_100,
            tags: ["developer", "prank", "BSOD", "windows", "blue", "crash"],
            createdAt: Date().addingTimeInterval(-86400 * 340),
            rank: 3,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("octoscreen"),
            name: "Octoscreen",
            description: "A screensaver featuring GitHub's Octicons gently floating and drifting across your screen. Open-source pride on display.",
            category: .developer,
            thumbnailURL: "octoscreen",
            downloadURL: "https://github.com/octoscreen",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.0,
            downloadCount: 7_200,
            tags: ["developer", "github", "octicons", "icons", "open-source"],
            createdAt: Date().addingTimeInterval(-86400 * 280),
            rank: nil,
            resolution: "Retina",
            fileSize: "3MB",
            isNew: false
        ),
        
        // ╔══════════════════════════════════════════════════╗
        // ║               GRAPHICS (6)                       ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("electric-sheep"),
            name: "Electric Sheep",
            description: "An infinite, evolving artwork of fractal animations created collaboratively by thousands of computers. Do androids dream of fractal sheep?",
            category: .graphics,
            thumbnailURL: "electric_sheep",
            downloadURL: "https://electricsheep.org",
            isPremium: false,
            price: nil,
            author: "Scott Draves",
            rating: 4.7,
            downloadCount: 62_500,
            tags: ["fractal", "generative", "evolving", "art", "collaborative"],
            createdAt: Date().addingTimeInterval(-86400 * 400),
            rank: 1,
            resolution: "4K",
            fileSize: "Dynamic",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("screensson"),
            name: "Screensson",
            description: "Creates unique abstract patterns on your display by randomly stacking and compositing vector stencils. Every frame is a new artwork.",
            category: .graphics,
            thumbnailURL: "screensson",
            downloadURL: "https://screensson.com",
            isPremium: false,
            price: nil,
            author: "Screensson",
            rating: 4.3,
            downloadCount: 9_800,
            tags: ["generative", "art", "vector", "stencil", "abstract", "pattern"],
            createdAt: Date().addingTimeInterval(-86400 * 270),
            rank: nil,
            resolution: "Retina",
            fileSize: "5MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("emoji-saver"),
            name: "Emoji Saver",
            description: "Animates Apple, EmojiOne, and Twitter emojis across your screen in 7 different dazzling effects with extensive customization options.",
            category: .graphics,
            thumbnailURL: "emoji_saver",
            downloadURL: "https://emojisaver.com",
            isPremium: true,
            price: 3.00,
            author: "Emoji Saver Studio",
            rating: 4.2,
            downloadCount: 14_700,
            tags: ["emoji", "animation", "fun", "colorful", "customizable"],
            createdAt: Date().addingTimeInterval(-86400 * 200),
            rank: nil,
            resolution: "Retina",
            fileSize: "12MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("life-saver"),
            name: "Life Saver",
            description: "A designer-friendly, beautifully rendered abstract visualization of Conway's Game of Life. Emergence has never looked this good.",
            category: .graphics,
            thumbnailURL: "life_saver",
            downloadURL: "https://www.yourlifesaver.com",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.5,
            downloadCount: 24_600,
            tags: ["generative", "conway", "cellular", "life", "abstract", "simulation"],
            createdAt: Date().addingTimeInterval(-86400 * 180),
            rank: 2,
            resolution: "4K",
            fileSize: "4MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("electropaintosx"),
            name: "ElectropaintOSX",
            description: "A faithful port of the legendary Silicon Graphics Electropaint screensaver. Mesmerizing 3D tubes of light flowing through space.",
            category: .graphics,
            thumbnailURL: "electropaint",
            downloadURL: "https://github.com/electropaint",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.4,
            downloadCount: 11_200,
            tags: ["graphics", "SGI", "3D", "light", "tubes", "retro"],
            createdAt: Date().addingTimeInterval(-86400 * 160),
            rank: nil,
            resolution: "4K",
            fileSize: "3MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("ealain"),
            name: "Ealain",
            description: "Infinite, forever-changing abstract art generated by Stable Diffusion. AI-powered beauty that never repeats, straight from the neural network.",
            category: .graphics,
            thumbnailURL: "ealain",
            downloadURL: "https://github.com/amiantos/ealain",
            isPremium: false,
            price: nil,
            author: "Brad Root",
            rating: 4.6,
            downloadCount: 18_900,
            tags: ["AI", "generative", "stable-diffusion", "art", "abstract", "neural"],
            createdAt: Date().addingTimeInterval(-86400 * 25),
            rank: 3,
            resolution: "4K",
            fileSize: "Dynamic",
            isNew: true
        ),
        
        // ╔══════════════════════════════════════════════════╗
        // ║                 OTHER (3)                        ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("google-trends"),
            name: "Google Trends",
            description: "Displays the latest hot searches from Google Trends in real time. See what the world is searching for, rendered beautifully.",
            category: .other,
            thumbnailURL: "google_trends",
            downloadURL: "https://github.com/googletrends",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.1,
            downloadCount: 8_700,
            tags: ["google", "trends", "search", "data", "live", "web"],
            createdAt: Date().addingTimeInterval(-86400 * 100),
            rank: nil,
            resolution: "Retina",
            fileSize: "2MB",
            isNew: true
        ),
        
        Screensaver(
            id: stableUUID("last-statement"),
            name: "Last Statement",
            description: "Displays the final words and last statements in a solemn, typographic presentation. A thought-provoking and sobering screensaver.",
            category: .other,
            thumbnailURL: "last_statement",
            downloadURL: "https://github.com/laststatement",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 3.8,
            downloadCount: 4_600,
            tags: ["typography", "sobering", "words", "statement", "thought"],
            createdAt: Date().addingTimeInterval(-86400 * 110),
            rank: nil,
            resolution: "Retina",
            fileSize: "1MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("macos-live"),
            name: "macOS Live Screensaver",
            description: "Plays live video streams from YouTube and HLS sources as your screensaver. Stream anything — live cams, music, nature feeds.",
            category: .other,
            thumbnailURL: "macos_live",
            downloadURL: "https://github.com/macoslive",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.3,
            downloadCount: 15_200,
            tags: ["live", "video", "youtube", "stream", "HLS", "webcam"],
            createdAt: Date().addingTimeInterval(-86400 * 50),
            rank: nil,
            resolution: "Dynamic",
            fileSize: "Dynamic",
            isNew: true
        ),
        
        // ╔══════════════════════════════════════════════════╗
        // ║              COLLECTIONS (2)                     ║
        // ╚══════════════════════════════════════════════════╝
        
        Screensaver(
            id: stableUUID("spotify-artwork"),
            name: "Spotify Artwork",
            description: "A screensaver inspired by the iTunes artwork visualizer, but for Spotify and Last.fm. Displays album art from your current music.",
            category: .collections,
            thumbnailURL: "spotify_artwork",
            downloadURL: "https://github.com/spotifyartwork",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.4,
            downloadCount: 22_800,
            tags: ["music", "spotify", "album", "artwork", "lastfm"],
            createdAt: Date().addingTimeInterval(-86400 * 170),
            rank: 1,
            resolution: "Retina",
            fileSize: "6MB",
            isNew: false
        ),
        
        Screensaver(
            id: stableUUID("bjorn-johansson"),
            name: "Bjorn Johansson Collection",
            description: "A curated collection of digital art screensavers by designer Bjorn Johansson. Abstract, geometric, and hauntingly beautiful.",
            category: .collections,
            thumbnailURL: "bjorn_johansson",
            downloadURL: "https://github.com/bjornjohansson",
            isPremium: false,
            price: nil,
            author: "Bjorn Johansson",
            rating: 4.5,
            downloadCount: 12_300,
            tags: ["art", "design", "abstract", "geometric", "collection", "curated"],
            createdAt: Date().addingTimeInterval(-86400 * 80),
            rank: 2,
            resolution: "4K",
            fileSize: "18MB",
            isNew: true
        ),
    ]
}
