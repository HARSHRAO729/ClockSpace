//
//  Theme.swift
//  ClockSpace
//
//  Centralized design tokens for the ClockSpace glassmorphic dark-mode UI.
//

import SwiftUI

/// ClockSpace design system — all visual tokens live here.
enum CSTheme {
    
    // MARK: - Colors
    
    /// Primary background — deepest layer (rich indigo-black)
    static let backgroundPrimary = Color(hex: 0x0F0F23)
    
    /// Surface — cards, panels
    static let surface = Color(hex: 0x1E1B4B)
    
    /// Surface elevated — raised elements, hover states
    static let surfaceElevated = Color(hex: 0x1E293B)
    
    /// CTA / accent — actions, active states, badges
    static let accent = Color(hex: 0x22C55E)
    
    /// Accent dimmed — subtle accent usage (backgrounds, tags)
    static let accentDimmed = Color(hex: 0x22C55E).opacity(0.15)
    
    /// Primary text
    static let textPrimary = Color(hex: 0xF8FAFC)
    
    /// Secondary / muted text
    static let textMuted = Color(hex: 0x94A3B8)
    
    /// Tertiary text — timestamps, metadata
    static let textTertiary = Color(hex: 0x64748B)
    
    /// Glass border
    static let glassBorder = Color.white.opacity(0.12)
    
    /// Subtle divider
    static let divider = Color.white.opacity(0.06)
    
    /// Danger / destructive actions
    static let danger = Color(hex: 0xEF4444)
    
    /// Warning
    static let warning = Color(hex: 0xF59E0B)
    
    /// Premium gold
    static let premiumGold = Color(hex: 0xFBBF24)
    
    /// CivicEase brand indigo
    static let civicEase = Color(hex: 0x4338CA)
    
    /// Violet accent for custom category
    static let violet = Color(hex: 0x8B5CF6)
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 100
    }
    
    // MARK: - Shadows
    
    enum Shadow {
        /// Subtle drop shadow for glassmorphic cards
        static let glass = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 24,
            x: 0,
            y: 8
        )
        
        /// Glow effect for accent-colored elements
        static let accentGlow = ShadowStyle(
            color: CSTheme.accent.opacity(0.3),
            radius: 16,
            x: 0,
            y: 4
        )
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
    }
    
    // MARK: - Typography
    
    enum Font {
        /// Massive hero title — SF Pro Display equivalent
        static let heroTitle = SwiftUI.Font.system(size: 42, weight: .bold, design: .default)
        /// Section titles
        static let sectionTitle = SwiftUI.Font.system(size: 24, weight: .bold, design: .default)
        static let largeTitle = SwiftUI.Font.system(size: 28, weight: .bold, design: .default)
        static let title = SwiftUI.Font.system(size: 22, weight: .semibold, design: .default)
        static let headline = SwiftUI.Font.system(size: 17, weight: .semibold, design: .default)
        static let body = SwiftUI.Font.system(size: 14, weight: .regular, design: .default)
        static let callout = SwiftUI.Font.system(size: 13, weight: .medium, design: .default)
        static let caption = SwiftUI.Font.system(size: 11, weight: .regular, design: .default)
        static let captionBold = SwiftUI.Font.system(size: 11, weight: .semibold, design: .default)
        /// Tiny label — "by CivicEase" branding
        static let micro = SwiftUI.Font.system(size: 9, weight: .medium, design: .default)
    }
}

// MARK: - Shadow Style Container

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Hex Initializer

extension Color {
    /// Initialize a Color from a hex integer, e.g. `Color(hex: 0x0F172A)`
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
