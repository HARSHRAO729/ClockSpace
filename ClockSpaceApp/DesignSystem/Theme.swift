//
//  Theme.swift
//  ClockSpace
//
//  Design tokens for the dark UI. Only tokens the app uses live here.
//

import SwiftUI

enum CSTheme {

    // MARK: - Colors

    static let backgroundPrimary = Color(hex: 0x0A0A14)
    static let surfaceElevated = Color(hex: 0x1E1E3F)

    /// Brand indigo (primary accent)
    static let accent = Color(hex: 0x6366F1)
    /// Brand violet (background glow)
    static let violet = Color(hex: 0x8B5CF6)
    /// CivicEase brand colour (background glow)
    static let civicEase = Color(hex: 0x4F46E5)

    static let textMuted = Color(hex: 0x94A3B8)
    static let textTertiary = Color(hex: 0x64748B)

    static let success = Color(hex: 0x10B981)

    // MARK: - Spacing

    enum Spacing {
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
    }

    // MARK: - Animation

    enum Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
    }

    // MARK: - Typography

    enum Font {
        static let sectionTitle = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 18, weight: .bold, design: .default)
        static let body = SwiftUI.Font.system(size: 15, weight: .regular, design: .default)
        static let caption = SwiftUI.Font.system(size: 12, weight: .medium, design: .default)
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
