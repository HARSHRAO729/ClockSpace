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
    
    // MARK: - Mock Data
    
    private static let mockScreensavers: [Screensaver] = [
        // ── Free ──
        Screensaver(
            id: UUID(),
            name: "Midnight Aurora",
            description: "A mesmerizing aurora borealis simulation with dynamic particle systems flowing across a deep arctic sky.",
            category: .free,
            thumbnailURL: "midnight_aurora",
            downloadURL: "https://cdn.clockspace.dev/savers/midnight-aurora.saver",
            isPremium: false,
            price: nil,
            author: "Stellar Labs",
            rating: 4.5,
            downloadCount: 28_400,
            tags: ["aurora", "particles", "night", "nature"],
            createdAt: Date().addingTimeInterval(-86400 * 30),
            rank: nil,
            resolution: "4K",
            fileSize: "18MB",
            isNew: true
        ),
        Screensaver(
            id: UUID(),
            name: "Minimal Clock",
            description: "A clean, typographic clock face with smooth second-hand animation on a pure black canvas.",
            category: .free,
            thumbnailURL: "minimal_clock",
            downloadURL: "https://cdn.clockspace.dev/savers/minimal-clock.saver",
            isPremium: false,
            price: nil,
            author: "ClockSpace",
            rating: 4.8,
            downloadCount: 52_100,
            tags: ["clock", "minimal", "typography", "dark"],
            createdAt: Date().addingTimeInterval(-86400 * 60),
            rank: 1,
            resolution: "Retina",
            fileSize: "4MB",
            isNew: false
        ),
        
        // ── Premium ──
        Screensaver(
            id: UUID(),
            name: "Liquid Metal",
            description: "Photorealistic metallic fluid dynamics rendered in real-time. Chrome, gold, and obsidian presets included.",
            category: .premium,
            thumbnailURL: "liquid_metal",
            downloadURL: "https://cdn.clockspace.dev/savers/liquid-metal.saver",
            isPremium: true,
            price: 4.99,
            author: "Flux Studio",
            rating: 4.9,
            downloadCount: 12_700,
            tags: ["3D", "metal", "fluid", "premium", "render"],
            createdAt: Date().addingTimeInterval(-86400 * 14),
            rank: 2,
            resolution: "4K@60",
            fileSize: "42MB",
            isNew: true
        ),
        Screensaver(
            id: UUID(),
            name: "Nebula Deep Field",
            description: "A journey through procedurally generated deep-space nebulae with volumetric lighting and star fields.",
            category: .premium,
            thumbnailURL: "nebula_deep",
            downloadURL: "https://cdn.clockspace.dev/savers/nebula-deep.saver",
            isPremium: true,
            price: 6.99,
            author: "Cosmos Digital",
            rating: 4.7,
            downloadCount: 8_300,
            tags: ["space", "nebula", "3D", "stars", "premium"],
            createdAt: Date().addingTimeInterval(-86400 * 7),
            rank: 3,
            resolution: "5K",
            fileSize: "28MB",
            isNew: false
        ),
        
        // ── Custom ──
        Screensaver(
            id: UUID(),
            name: "Shader Playground",
            description: "Write your own GLSL/Metal shaders and preview them as screensavers in real time.",
            category: .custom,
            thumbnailURL: "shader_playground",
            downloadURL: "https://cdn.clockspace.dev/savers/shader-playground.saver",
            isPremium: false,
            price: nil,
            author: "Community",
            rating: 4.2,
            downloadCount: 3_600,
            tags: ["shader", "code", "custom", "creative", "GLSL"],
            createdAt: Date().addingTimeInterval(-86400 * 45),
            rank: nil,
            resolution: "Dynamic",
            fileSize: "2MB",
            isNew: false
        ),
        Screensaver(
            id: UUID(),
            name: "Photo Mosaic Engine",
            description: "Turn your photo library into a living mosaic screensaver with configurable tile sizes and transitions.",
            category: .custom,
            thumbnailURL: "photo_mosaic",
            downloadURL: "https://cdn.clockspace.dev/savers/photo-mosaic.saver",
            isPremium: false,
            price: nil,
            author: "PixelForge",
            rating: 4.4,
            downloadCount: 5_100,
            tags: ["photo", "mosaic", "custom", "personal"],
            createdAt: Date().addingTimeInterval(-86400 * 20),
            rank: nil,
            resolution: "Retina",
            fileSize: "12MB",
            isNew: true
        ),
    ]
}
