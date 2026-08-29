//
//  APIManager.swift
//  ClockSpace
//
//  Stubbed API service for the screensaver marketplace.
//  Returns mock data for the MVP. Swap implementations for production.
//

import Foundation
import Combine
import SwiftUI

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
        // Populate with empty catalog
        self.screensavers = []
        loadLikedItems()
    }
    
    /// Static property for migration access
    static var mockScreensavers: [Screensaver] {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Screensaver].self, from: data)) ?? []
    }

    // MARK: - Remote Catalog (Cloudflare R2)

    /// Public URL of the catalog hosted on Cloudflare R2. Replaces Firestore.
    private static let catalogURL = URL(string: "https://pub-78f2a94f0b354729b9535c615d11e9a9.r2.dev/catalog.json")!

    /// GETs the static catalog.json from the CDN. Returns [] on any failure so the
    /// caller falls back to the bundled copy.
    private static func fetchRemoteCatalog() async -> [Screensaver] {
        var request = URLRequest(url: catalogURL)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadRevalidatingCacheData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Screensaver].self, from: data)
        } catch {
            print("⚠️ Remote catalog fetch failed: \(error.localizedDescription). Falling back to bundled data.")
            return []
        }
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
        
        // 1. Fetch the static catalog.json from the CDN (Cloudflare R2).
        //    URLSession's own request timeout replaces the old manual race against
        //    the non-cooperative Firestore SDK.
        var allSavers = await Self.fetchRemoteCatalog()

        // 2. Fall back to the catalog bundled in the app if the network fetch failed.
        if allSavers.isEmpty {
            print("💡 Using bundled catalog fallback.")
            allSavers = APIManager.mockScreensavers
        }
        
        self.screensavers = allSavers
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
        
        let allSavers = APIManager.mockScreensavers.isEmpty ? self.screensavers : APIManager.mockScreensavers
        
        let lowered = query.lowercased()
        let results = allSavers.filter { saver in
            saver.name.lowercased().contains(lowered) ||
            saver.author.lowercased().contains(lowered) ||
            saver.tags.contains(where: { $0.lowercased().contains(lowered) })
        }
        
            screensavers = results
        isLoading = false
        return results
    }

    /// Refreshes the catalog by fetching from the cloud.
    func refreshCatalog() async {
        _ = try? await fetchScreensavers()
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

}
