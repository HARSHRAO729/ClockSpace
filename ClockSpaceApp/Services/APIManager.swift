//
//  APIManager.swift
//  ClockSpace
//
//  Loads the screensaver catalog and keeps the user's favourites.
//
//  The catalog is a static catalog.json on the CDN. On launch the app shows the
//  last copy it saved (or the one bundled in the app), then refreshes from the CDN.
//

import Foundation
import os
import Combine

@MainActor
final class APIManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var screensavers: [Screensaver] = []
    /// True when the last refresh from the CDN failed and a saved copy is shown.
    @Published private(set) var isOffline: Bool = false
    @Published var detailedScreensaver: Screensaver? = nil
    @Published var likedIDs: Set<UUID> = []

    // MARK: - Singleton

    static let shared = APIManager()

    private init() {
        loadLikedItems()
        // The saved (or bundled) copy is on screen immediately; refreshCatalog() updates it.
        screensavers = Self.forThisMac(Self.savedCatalog() ?? Self.bundledCatalog())
    }

    // MARK: - Catalog

    /// The catalog, most recently added first.
    var newestFirst: [Screensaver] {
        screensavers.sorted { $0.createdAt > $1.createdAt }
    }

    /// The catalog sorted by name.
    var alphabetical: [Screensaver] {
        screensavers.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Entries with a `rank` in rank order; the first six entries if none are ranked.
    var featured: [Screensaver] {
        let ranked = screensavers.filter { $0.rank != nil }.sorted { ($0.rank ?? 0) < ($1.rank ?? 0) }
        return ranked.isEmpty ? Array(screensavers.prefix(6)) : ranked
    }

    /// Categories that contain at least one screensaver, most populated first.
    var categoriesInUse: [(category: Category, count: Int)] {
        Dictionary(grouping: screensavers, by: \.category)
            .map { (category: $0.key, count: $0.value.count) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.category.displayName < $1.category.displayName }
    }

    func screensavers(in category: Category) -> [Screensaver] {
        alphabetical.filter { $0.category == category }
    }

    /// Matches name, author, tags and category name; ignores case and accents.
    func search(_ text: String) -> [Screensaver] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        func matches(_ field: String) -> Bool {
            field.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
        return alphabetical.filter { saver in
            matches(saver.name) || matches(saver.author) || matches(saver.category.displayName)
                || saver.tags.contains(where: matches)
        }
    }

    /// Refreshes the catalog from the CDN and saves it for next launch. Call once per launch.
    func refreshCatalog() async {
        do {
            let (data, savers) = try await Self.fetchRemoteCatalog()
            screensavers = Self.forThisMac(savers)
            isOffline = false
            Self.saveCatalog(data)
        } catch {
            isOffline = true
            CSConstants.log.error("Catalog refresh failed: \(error.localizedDescription, privacy: .public). Showing saved copy.")
        }
    }

    /// Hides screensavers that have no Intel code when running on an Intel Mac.
    static func forThisMac(_ savers: [Screensaver], appleSilicon: Bool = CSConstants.isAppleSilicon) -> [Screensaver] {
        appleSilicon ? savers : savers.filter { !$0.appleSiliconOnly }
    }

    private enum CatalogError: LocalizedError {
        case badStatus(Int)
        case empty
        var errorDescription: String? {
            switch self {
            case .badStatus(let code): return "HTTP \(code)"
            case .empty: return "Catalog has no readable entries"
            }
        }
    }

    private static func fetchRemoteCatalog() async throws -> (Data, [Screensaver]) {
        var request = URLRequest(url: CSConstants.catalogURL)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadRevalidatingCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw CatalogError.badStatus(status) }
        let savers = try Screensaver.decodeCatalog(from: data)
        guard !savers.isEmpty else { throw CatalogError.empty }
        return (data, savers)
    }

    /// The catalog shipped inside the app, used until a download succeeds.
    static func bundledCatalog() -> [Screensaver] {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? Screensaver.decodeCatalog(from: data)) ?? []
    }

    // MARK: - Last good copy (Application Support)

    private static var savedCatalogURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "CivicEase.ClockSpace", directoryHint: .isDirectory)
            .appending(path: "catalog.json")
    }

    private static func savedCatalog() -> [Screensaver]? {
        guard let data = try? Data(contentsOf: savedCatalogURL),
              let savers = try? Screensaver.decodeCatalog(from: data),
              !savers.isEmpty else { return nil }
        return savers
    }

    private static func saveCatalog(_ data: Data) {
        do {
            try FileManager.default.createDirectory(
                at: savedCatalogURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: savedCatalogURL, options: .atomic)
        } catch {
            CSConstants.log.error("Could not save catalog: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Favourites

    func clearLikedItems() {
        likedIDs.removeAll()
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
}
