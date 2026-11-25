//
//  ImagePipeline.swift
//  ClockSpace
//
//  Downloads, caches and decodes thumbnails off the main thread.
//
//  • Disk cache: the system URLCache, keyed by full URL, revalidated with the
//    CDN's ETag/Last-Modified headers, so a replaced image is picked up.
//  • Offline: falls back to whatever the disk cache holds.
//  • Memory cache: decoded images, so scrolling back never decodes twice.
//  • One download per URL, however many views ask for it at once.
//

import Foundation
import CoreGraphics
import ImageIO

actor ImagePipeline {

    static let shared = ImagePipeline()

    private let session: URLSession
    // NSCache is documented as thread-safe but isn't marked Sendable, hence `unsafe`.
    private nonisolated(unsafe) let memory = NSCache<NSURL, CGImage>()
    private var inFlight: [URL: Task<CGImage?, Never>] = [:]

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        // Remove the hand-written cache used up to 1.0 (keyed by file name only).
        try? FileManager.default.removeItem(at: caches.appending(path: "com.clockspace.thumbnails"))

        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            directory: caches.appending(path: "CivicEase.ClockSpace/Images", directoryHint: .isDirectory))
        // Always ask the server (a 304 when unchanged): R2 sends no Cache-Control, so the
        // default policy would treat old pictures as fresh for days after they change.
        config.requestCachePolicy = .reloadRevalidatingCacheData
        session = URLSession(configuration: config)
        memory.countLimit = 200
    }

    /// Already-decoded image, if any. Safe from any thread (NSCache is thread-safe).
    nonisolated func cachedImage(for urlString: String) -> CGImage? {
        guard let url = Self.url(urlString) else { return nil }
        return memory.object(forKey: url as NSURL)
    }

    /// Returns the decoded image, downloading it if needed. Never throws: nil means "no picture".
    func image(for urlString: String) async -> CGImage? {
        guard let url = Self.url(urlString) else { return nil }
        if let cached = memory.object(forKey: url as NSURL) { return cached }
        if let running = inFlight[url] { return await running.value }

        let session = self.session
        let task = Task.detached(priority: .utility) { () -> CGImage? in
            guard let data = await Self.fetch(url, session: session) else { return nil }
            return Self.decode(data)
        }
        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        if let image { memory.setObject(image, forKey: url as NSURL) }
        return image
    }

    // MARK: - Helpers

    private static func url(_ string: String) -> URL? {
        guard let url = URL(string: string), url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }

    /// Network first (revalidating the cache); if that fails, whatever is cached on disk.
    private static func fetch(_ url: URL, session: URLSession) async -> Data? {
        if let (data, response) = try? await session.data(from: url),
           (response as? HTTPURLResponse)?.statusCode == 200 {
            return data
        }
        var offline = URLRequest(url: url)
        offline.cachePolicy = .returnCacheDataDontLoad
        if let (data, _) = try? await session.data(for: offline), !data.isEmpty {
            return data
        }
        return nil
    }

    /// Fully decodes now (on this background thread) so drawing never decodes on the main thread.
    private static func decode(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        return CGImageSourceCreateImageAtIndex(source, 0, options)
    }
}
