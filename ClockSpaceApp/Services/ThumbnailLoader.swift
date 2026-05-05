//
//  ThumbnailLoader.swift
//  ClockSpace
//
//  Centralized thumbnail resolution utility.
//  Eliminates hardcoded paths and duplicated image-loading logic
//  scattered across HeroView, ExploreView, ScreensaverCard, and DetailView.
//

import AppKit
import SwiftUI

/// Resolves screensaver thumbnail images from the app bundle.
/// Searches in this priority order:
///   1. Asset Catalog (by name, without extension)
///   2. Bundle "Thumbnails" subdirectory
///   3. Bundle "Categories" subdirectory
///   4. Returns nil → caller should show a gradient fallback
enum ThumbnailLoader {
    
    /// Attempt to load an `NSImage` for the given thumbnail identifier.
    /// - Parameter identifier: The `thumbnailURL` string from a `Screensaver` model.
    /// - Returns: The resolved image, or `nil` if no match is found.
    static func loadImage(named identifier: String) -> NSImage? {
        guard identifier != "placeholder", !identifier.isEmpty else { return nil }
        
        let resourceName = (identifier as NSString).deletingPathExtension
        let ext = (identifier as NSString).pathExtension
        let searchExtension = ext.isEmpty ? nil : ext
        
        // 1. Asset Catalog (highest priority — Xcode optimizes these)
        if let image = NSImage(named: identifier) {
            return image
        }
        
        // 2. "Thumbnails" subdirectory in the app bundle
        if let url = Bundle.main.url(forResource: resourceName, withExtension: searchExtension, subdirectory: "Thumbnails"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        
        // 3. "Categories" subdirectory in the app bundle
        if let url = Bundle.main.url(forResource: resourceName, withExtension: searchExtension, subdirectory: "Categories"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        
        // 4. Root bundle resources (loose files)
        if let url = Bundle.main.url(forResource: resourceName, withExtension: searchExtension),
           let image = NSImage(contentsOf: url) {
            return image
        }
        
        return nil
    }
    
    /// Load a category preview image from the bundle.
    /// Searches the "Categories" subdirectory and falls back to the asset catalog.
    static func loadCategoryImage(for category: Category) -> NSImage? {
        let baseName = category.imageName
        let exts = ["png", "jpg", "jpeg", "webp"]
        
        for ext in exts {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "Categories"),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }
        
        // Fallback to asset catalog
        return NSImage(named: baseName)
    }
    
    /// Returns a SwiftUI `Image` view for the given thumbnail, or `nil`.
    @ViewBuilder
    static func thumbnailImage(for identifier: String) -> some View {
        if let nsImage = loadImage(named: identifier) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}
