//
//  GlassModifier.swift
//  ClockSpace
//
//  Reusable glassmorphism ViewModifier for the ClockSpace design system.
//

import SwiftUI

/// Applies a frosted-glass effect: translucent background, blur, subtle border, and shadow.
struct GlassModifier: ViewModifier {
    
    var cornerRadius: CGFloat = CSTheme.Radius.large
    var borderOpacity: Double = 0.12
    var backgroundOpacity: Double = 0.65
    var blurRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base frosted layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(CSTheme.surface.opacity(backgroundOpacity))
                    
                    // System vibrancy material for native macOS blur
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.4)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: CSTheme.Shadow.glass.color,
                radius: CSTheme.Shadow.glass.radius,
                x: CSTheme.Shadow.glass.x,
                y: CSTheme.Shadow.glass.y
            )
    }
}

/// A lighter variant for nested glassy elements (cards inside glass panels).
struct GlassCardModifier: ViewModifier {
    
    var cornerRadius: CGFloat = CSTheme.Radius.medium
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(CSTheme.surfaceElevated.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(CSTheme.glassBorder, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - View Extensions

extension View {
    /// Apply the standard glassmorphic panel effect.
    func glass(
        cornerRadius: CGFloat = CSTheme.Radius.large,
        borderOpacity: Double = 0.12,
        backgroundOpacity: Double = 0.65
    ) -> some View {
        modifier(GlassModifier(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            backgroundOpacity: backgroundOpacity
        ))
    }
    
    /// Apply a lighter glass effect for cards nested inside glass panels.
    func glassCard(cornerRadius: CGFloat = CSTheme.Radius.medium) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
