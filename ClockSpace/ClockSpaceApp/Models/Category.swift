//
//  Category.swift
//  ClockSpace
//
//  Screensaver marketplace categories.
//

import SwiftUI

/// Marketplace category tiers for screensaver organization.
enum Category: String, Codable, CaseIterable, Identifiable {
    case free = "Free"
    case premium = "Premium"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    /// SF Symbol name for sidebar navigation.
    var iconName: String {
        switch self {
        case .free:     return "gift"
        case .premium:  return "crown"
        case .custom:   return "paintbrush.pointed"
        }
    }
    
    /// Short description for category headers.
    var subtitle: String {
        switch self {
        case .free:     return "Community-made screensavers"
        case .premium:  return "Curated premium experiences"
        case .custom:   return "Build your own screensaver"
        }
    }
    
    /// Accent color per category for visual distinction.
    var tintColor: Color {
        switch self {
        case .free:     return CSTheme.accent
        case .premium:  return CSTheme.premiumGold
        case .custom:   return Color(hex: 0x8B5CF6) // violet-500
        }
    }
}
