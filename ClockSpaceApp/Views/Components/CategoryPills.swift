//
//  CategoryPills.swift
//  ClockSpace
//
//  Hollow pill-shaped category tags with thin borders.
//  Replaces sidebar navigation with inline filter pills.
//

import SwiftUI

struct CategoryPills: View {
    
    @Binding var selectedCategory: Category?
    @State private var hoveredCategory: Category?
    
    var body: some View {
        HStack(spacing: CSTheme.Spacing.sm) {
            // "All" pill
            PillTag(
                label: "All",
                isSelected: selectedCategory == nil,
                isHovered: hoveredCategory == nil,
                tintColor: CSTheme.accent
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedCategory = nil
                }
            }
            
            ForEach(Category.allCases) { category in
                PillTag(
                    label: category.rawValue,
                    isSelected: selectedCategory == category,
                    isHovered: hoveredCategory == category,
                    tintColor: category.tintColor
                ) {
                    withAnimation(CSTheme.Animation.standard) {
                        selectedCategory = (selectedCategory == category) ? nil : category
                    }
                }
                .onHover { hovering in
                    hoveredCategory = hovering ? category : nil
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Individual Pill Tag

struct PillTag: View {
    
    let label: String
    let isSelected: Bool
    let isHovered: Bool
    let tintColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : (isHovered ? CSTheme.textPrimary : CSTheme.textMuted))
                .padding(.horizontal, CSTheme.Spacing.lg)
                .padding(.vertical, CSTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? tintColor.opacity(0.2) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                                ? tintColor.opacity(0.5)
                                : (isHovered ? Color.white.opacity(0.2) : Color.white.opacity(0.1)),
                            lineWidth: isSelected ? 1.0 : 0.5
                        )
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
