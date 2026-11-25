//
//  Screensaver.swift
//  ClockSpace
//
//  One entry of the screensaver catalog (catalog.json).
//

import Foundation

/// A single screensaver listing.
///
/// Decoding is deliberately forgiving: only `id`, `name` and `downloadURL` are
/// required, every other field falls back to a default, and unknown keys are
/// ignored. Older and newer catalogs therefore keep loading.
struct Screensaver: Identifiable, Decodable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let category: Category
    let thumbnailURL: String
    let downloadURL: String
    let author: String
    let tags: [String]
    let createdAt: Date
    let rank: Int?            // Featured order (1 = first)
    let fileSize: String?     // Display text, e.g. "58 KB"

    // Added in 1.1 — all optional, so the 1.0 app can still read the same catalog.
    let sha256: String?            // Checksum of the downloaded zip
    let sourceURL: String?         // Upstream project page
    let license: String?           // Upstream licence name
    let appleSiliconOnly: Bool     // No Intel slice in the bundle

    /// Shown with a NEW badge for 30 days after it was added.
    var isNew: Bool {
        Date().timeIntervalSince(createdAt) < 30 * 24 * 60 * 60
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, category, thumbnailURL, downloadURL, author, tags, createdAt
        case rank, fileSize, sha256, sourceURL, license, appleSiliconOnly
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        downloadURL = try c.decode(String.self, forKey: .downloadURL)
        description = (try? c.decodeIfPresent(String.self, forKey: .description)) ?? ""
        category = (try? c.decodeIfPresent(Category.self, forKey: .category)) ?? .other
        thumbnailURL = (try? c.decodeIfPresent(String.self, forKey: .thumbnailURL)) ?? ""
        author = (try? c.decodeIfPresent(String.self, forKey: .author)) ?? "Unknown"
        tags = (try? c.decodeIfPresent([String].self, forKey: .tags)) ?? []
        createdAt = (try? c.decodeIfPresent(Date.self, forKey: .createdAt)) ?? .distantPast
        rank = try? c.decodeIfPresent(Int.self, forKey: .rank)
        fileSize = try? c.decodeIfPresent(String.self, forKey: .fileSize)
        sha256 = try? c.decodeIfPresent(String.self, forKey: .sha256)
        sourceURL = try? c.decodeIfPresent(String.self, forKey: .sourceURL)
        license = try? c.decodeIfPresent(String.self, forKey: .license)
        appleSiliconOnly = (try? c.decodeIfPresent(Bool.self, forKey: .appleSiliconOnly)) ?? false
    }

    /// Decodes a catalog, skipping any entry that cannot be read
    /// instead of failing the whole list. Throws only if the data is not a JSON array.
    static func decodeCatalog(from data: Data) throws -> [Screensaver] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([Lenient].self, from: data)
        return entries.compactMap(\.value)
    }

    /// Wraps one array element so a bad entry becomes `nil` rather than an error.
    private struct Lenient: Decodable {
        let value: Screensaver?
        init(from decoder: Decoder) throws {
            value = try? Screensaver(from: decoder)
        }
    }
}

// MARK: - Install State

/// The possible states of the install button.
enum InstallState {
    case ready       // Not installed
    case installing  // In progress
    case installed   // On disk
}
