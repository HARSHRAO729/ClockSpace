//
//  ScreensaverGradients.swift
//  ClockSpace
//
//  Shared gradient palette for screensaver cards, detail backgrounds,
//  and hero views. Eliminates identical gradient arrays duplicated
//  across ScreensaverCard, ScreensaverDetailView, and HeroView.
//

import SwiftUI

/// Centralized gradient palette for screensaver visual fallbacks.
enum ScreensaverGradients {
    
    // MARK: - Card / Detail Gradients (deep, immersive)
    
    /// Rich multi-stop gradients for card thumbnails and detail backgrounds.
    static let cardPalette: [LinearGradient] = [
        LinearGradient(colors: [Color(hex: 0x0F172A), Color(hex: 0x1E3A5F), Color(hex: 0x0F766E)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: 0x1A1A2E), Color(hex: 0x16213E), Color(hex: 0x0F3460)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(hex: 0x2D1B69), Color(hex: 0x11998E)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: 0x0F0C29), Color(hex: 0x302B63), Color(hex: 0x24243E)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: 0x1F1C2C), Color(hex: 0x928DAB)], startPoint: .bottom, endPoint: .top),
        LinearGradient(colors: [Color(hex: 0x0D324D), Color(hex: 0x7F5A83)], startPoint: .topLeading, endPoint: .bottomTrailing),
    ]
    
    // MARK: - Hero Gradients (cinematic, top-to-bottom)
    
    /// Cinematic gradients for the hero carousel background.
    static let heroPalette: [LinearGradient] = [
        LinearGradient(colors: [Color(hex: 0x1E1B4B), Color(hex: 0x312E81), Color(hex: 0x4338CA).opacity(0.4)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(hex: 0x064E3B), Color(hex: 0x065F46), Color(hex: 0x047857).opacity(0.4)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(hex: 0x7C2D12), Color(hex: 0x9A3412), Color(hex: 0xB45309).opacity(0.4)], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [Color(hex: 0x4C1D95), Color(hex: 0x5B21B6), Color(hex: 0x6D28D9).opacity(0.4)], startPoint: .top, endPoint: .bottom),
    ]
    
    // MARK: - Public API
    
    /// Deterministic gradient for a screensaver based on its name hash.
    static func cardGradient(for screensaver: Screensaver) -> LinearGradient {
        let index = abs(screensaver.name.hashValue) % cardPalette.count
        return cardPalette[index]
    }
    
    /// Deterministic hero gradient for a screensaver.
    static func heroGradient(for screensaver: Screensaver) -> LinearGradient {
        let index = abs(screensaver.name.hashValue) % heroPalette.count
        return heroPalette[index]
    }
}
