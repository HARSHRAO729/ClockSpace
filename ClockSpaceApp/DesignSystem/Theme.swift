//
//  Theme.swift
//  ClockSpace
//
//  Centralized design tokens for the ClockSpace premium glassmorphic dark-mode UI.
//

import SwiftUI

/// ClockSpace design system — premium visual tokens.
enum CSTheme {
    
    // MARK: - Core Colors
    
    /// Primary background — deepest layer (rich cosmic indigo)
    static let backgroundPrimary = Color(hex: 0x0A0A14)
    
    /// Surface — cards, panels (glass base)
    static let surface = Color(hex: 0x14142B)
    
    /// Surface elevated — raised elements, hover states
    static let surfaceElevated = Color(hex: 0x1E1E3F)
    
    /// Brand Indigo (Primary Accent)
    static let accent = Color(hex: 0x6366F1)
    
    /// Brand Violet (Secondary Accent)
    static let violet = Color(hex: 0x8B5CF6)
    
    /// Premium Gold (Luxury Tier)
    static let premiumGold = Color(hex: 0xF59E0B)
    
    /// CivicEase Brand Color
    static let civicEase = Color(hex: 0x4F46E5)
    
    // MARK: - Text Colors
    
    static let textPrimary = Color(hex: 0xF8FAFC)
    static let textSecondary = Color(hex: 0xE2E8F0)
    static let textMuted = Color(hex: 0x94A3B8)
    static let textTertiary = Color(hex: 0x64748B)
    
    // MARK: - Semantic Colors
    
    static let success = Color(hex: 0x10B981)
    static let danger = Color(hex: 0xEF4444)
    static let warning = Color(hex: 0xF59E0B)
    static let info = Color(hex: 0x3B82F6)
    
    // MARK: - Decoration
    
    static let divider = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.12)
    
    static let accentGradient = LinearGradient(
        colors: [accent, violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 14
        static let large: CGFloat = 24
        static let xl: CGFloat = 32
        static let pill: CGFloat = 100
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let rapid = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let cinematic = SwiftUI.Animation.easeInOut(duration: 0.8)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.75)
    }
    
    // MARK: - Typography
    
    enum Font {
        static let heroTitle = SwiftUI.Font.system(size: 64, weight: .bold, design: .rounded)
        static let sectionTitle = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let largeTitle = SwiftUI.Font.system(size: 32, weight: .bold, design: .default)
        static let title = SwiftUI.Font.system(size: 22, weight: .semibold, design: .default)
        static let headline = SwiftUI.Font.system(size: 18, weight: .bold, design: .default)
        static let body = SwiftUI.Font.system(size: 15, weight: .regular, design: .default)
        static let callout = SwiftUI.Font.system(size: 13, weight: .semibold, design: .default)
        static let caption = SwiftUI.Font.system(size: 12, weight: .medium, design: .default)
        static let micro = SwiftUI.Font.system(size: 10, weight: .heavy, design: .default)
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
