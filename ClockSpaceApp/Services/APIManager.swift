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
    @Published var playlists: [String] = ["Favorites"] // Mock playlists
    
    // MARK: - Singleton
    
    static let shared = APIManager()
    
    private init() {
        // Force purge all local state for a fresh start as requested
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        
        // Populate with empty catalog
        self.screensavers = []
        loadLikedItems()
    }
    
    func clearLikedItems() {
        likedIDs.removeAll()
        playlists.removeAll() // Clear all user data
        UserDefaults.standard.removeObject(forKey: "cs_liked_ids")
        saveLikedItems()
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
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        let allSavers = Self.mockScreensavers
        
        // Update global catalog if it's empty
        if self.screensavers.isEmpty {
            self.screensavers = allSavers
        }
        
        isLoading = false
        
        if let category = category {
            return allSavers.filter { $0.category == category }
        } else {
            return allSavers
        }
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
    
    // MARK: - Complete Screensaver Catalog (Empty for Fresh Start)
    
        private static let mockScreensavers: [Screensaver] = [
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
            downloadURL: "local://DeveloperExcuses.saver",
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
            id: UUID(uuidString: "d2eeeac6-84fc-5130-bee8-aceeb6e958f6")!,
            name: "Developers Excuses",
            description: "Locally installed screensaver from source.",
            category: .abstract,
            thumbnailURL: "Developers-Excuses.jpg",
            downloadURL: "local://Developers Excuses.saver",
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
        )
    ]

}
