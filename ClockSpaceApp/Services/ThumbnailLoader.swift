//
//  ThumbnailLoader.swift
//  ClockSpace
//
//  Centralized thumbnail resolution utility.
//  Supports both local bundle resources and remote URLs with disk caching.
//

import AppKit
import SwiftUI

/// Resolves screensaver thumbnail images from the app bundle or remote URLs.
enum ThumbnailLoader {
    
    private static let cache = NSCache<NSString, NSImage>()
    
    private static var cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.clockspace.thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    /// Load an image — checks memory cache, disk cache, local bundle, then remote URL.
    static func loadImage(named identifier: String) -> NSImage? {
        guard !identifier.isEmpty, identifier != "placeholder" else { return nil }
        
        let key = identifier as NSString
        
        // 1. Memory cache
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        // 2. Disk cache (for previously downloaded remote images)
        let diskFile = cacheDir.appendingPathComponent(key.lastPathComponent)
        if FileManager.default.fileExists(atPath: diskFile.path),
           let image = NSImage(contentsOf: diskFile) {
            cache.setObject(image, forKey: key)
            return image
        }
        
        // 3. Local bundle resources
        if let image = loadFromBundle(identifier) {
            cache.setObject(image, forKey: key)
            return image
        }
        
        // 4. If it's a remote URL, start async download (returns nil this pass)
        if identifier.hasPrefix("http"), let url = URL(string: identifier) {
            downloadAsync(url: url, key: key)
        }
        
        return nil
    }
    
    // MARK: - Local Bundle Lookup
    
    private static func loadFromBundle(_ identifier: String) -> NSImage? {
        let resourceName = (identifier as NSString).deletingPathExtension
        let ext = (identifier as NSString).pathExtension
        let searchExtension = ext.isEmpty ? nil : ext
        
        // Asset Catalog
        if let image = NSImage(named: identifier) { return image }
        
        // "Thumbnails" subdirectory
        if let url = Bundle.main.url(forResource: resourceName, withExtension: searchExtension, subdirectory: "Thumbnails"),
           let image = NSImage(contentsOf: url) { return image }
        
        // temp_migration/thumbnails subdirectory
        if let url = Bundle.main.url(forResource: resourceName, withExtension: searchExtension, subdirectory: "temp_migration/thumbnails"),
           let image = NSImage(contentsOf: url) { return image }
        
        // "Categories" subdirectory
        if let url = Bundle.main.url(forResource: resourceName, withExtension: searchExtension, subdirectory: "Categories"),
           let image = NSImage(contentsOf: url) { return image }
        
        // Root bundle
        if let url = Bundle.main.url(forResource: resourceName, withExtension: searchExtension),
           let image = NSImage(contentsOf: url) { return image }
        
        return nil
    }
    
    // MARK: - Remote Download
    
    private static func downloadAsync(url: URL, key: NSString) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = NSImage(data: data) else { return }
            
            // Save to disk cache
            let diskFile = cacheDir.appendingPathComponent(key.lastPathComponent)
            try? data.write(to: diskFile)
            
            // Save to memory cache
            cache.setObject(image, forKey: key)
            
            // Post notification so views can refresh
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .thumbnailDidLoad, object: key)
            }
        }.resume()
    }
    
    /// Load a category preview image from the bundle.
    static func loadCategoryImage(for category: Category) -> NSImage? {
        let baseName = category.imageName
        let exts = ["png", "jpg", "jpeg", "webp"]
        
        for ext in exts {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "Categories"),
               let image = NSImage(contentsOf: url) { return image }
        }
        
        return NSImage(named: baseName)
    }
    
    @ViewBuilder
    static func thumbnailImage(for identifier: String) -> some View {
        if let nsImage = loadImage(named: identifier) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}

extension Notification.Name {
    static let thumbnailDidLoad = Notification.Name("thumbnailDidLoad")
}
