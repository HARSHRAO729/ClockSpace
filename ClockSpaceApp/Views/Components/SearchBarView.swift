//
//  SearchBarView.swift
//  ClockSpace
//
//  Glassmorphic search bar for the screensaver marketplace.
//

import SwiftUI

struct SearchBarView: View {
    
    @Binding var searchText: String
    @State private var isFocused: Bool = false
    @FocusState private var fieldFocused: Bool
    
    var body: some View {
        HStack(spacing: CSTheme.Spacing.md) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isFocused ? CSTheme.accent : CSTheme.textTertiary)
                .animation(CSTheme.Animation.fast, value: isFocused)
            
            // Text field
            TextField("Search screensavers...", text: $searchText)
                .textFieldStyle(.plain)
                .font(CSTheme.Font.body)
                .foregroundColor(CSTheme.textPrimary)
                .focused($fieldFocused)
                .onChange(of: fieldFocused) {
                    withAnimation(CSTheme.Animation.fast) {
                        isFocused = fieldFocused
                    }
                }
            
            // Clear button
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(CSTheme.Animation.fast) {
                        searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(CSTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
            
            // Keyboard shortcut hint
            HStack(spacing: 2) {
                Image(systemName: "command")
                    .font(.system(size: 9))
                Text("K")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
            }
            .foregroundColor(CSTheme.textTertiary.opacity(0.6))
            .padding(.horizontal, CSTheme.Spacing.sm)
            .padding(.vertical, CSTheme.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(CSTheme.surfaceElevated.opacity(0.4))
            )
        }
        .padding(.horizontal, CSTheme.Spacing.lg)
        .padding(.vertical, CSTheme.Spacing.md)
        .glass(
            cornerRadius: CSTheme.Radius.medium,
            borderOpacity: isFocused ? 0.25 : 0.12,
            backgroundOpacity: 0.5
        )
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.Radius.medium, style: .continuous)
                .stroke(
                    isFocused ? CSTheme.accent.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .animation(CSTheme.Animation.fast, value: isFocused)
    }
}

/* Preview hidden for CLI build */
