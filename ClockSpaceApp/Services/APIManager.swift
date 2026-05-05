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
        
        let allSavers: [Screensaver]
        do {
            allSavers = try await loadCatalog()
            self.screensavers = allSavers
        } catch {
            errorMessage = "Failed to load screensaver catalog: \(error.localizedDescription)"
            isLoading = false
            throw error
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
        
        let allSavers = (try? await loadCatalog()) ?? self.screensavers
        
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
    
    // MARK: - Screensaver Catalog Loading
    
    private let remoteCatalogURL = URL(string: "https://raw.githubusercontent.com/harshrao/ClockSpace/main/catalog.json")
    
    private func loadCatalog() async throws -> [Screensaver] {
        // 1. Try Remote First
        if let url = remoteCatalogURL {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let catalog = try decoder.decode([Screensaver].self, from: data)
                    return catalog
                }
            } catch {
                print("Remote catalog fetch failed, falling back to local: \(error)")
            }
        }
        
        // 2. Fallback to Local
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            print("Error: catalog.json not found in the app bundle.")
            return []
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Screensaver].self, from: data)
    }

}
