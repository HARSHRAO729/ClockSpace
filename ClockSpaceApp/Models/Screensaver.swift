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
    let rating: Double
    let downloadCount: Int
    let tags: [String]
    let createdAt: Date
    
    // Wallspace-style Metadata
    let rank: Int?            // 1, 2, 3 for "Most Popular"
    let resolution: String?   // "4K", "1920x1080"
    let fileSize: String?     // "23MB"
    let isNew: Bool           // To show "NEW" badge
    
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
    
    /// Star rating as an array of SF Symbol names for rendering
    var starIcons: [String] {
        var stars: [String] = []
        let fullStars = Int(rating)
        let hasHalf = (rating - Double(fullStars)) >= 0.5
        
        for _ in 0..<fullStars {
            stars.append("star.fill")
        }
        if hasHalf {
            stars.append("star.leadinghalf.filled")
        }
        while stars.count < 5 {
            stars.append("star")
        }
        return stars
    }
}
