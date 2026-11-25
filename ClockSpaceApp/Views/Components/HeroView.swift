//
//  HeroView.swift
//  ClockSpace
//
//  The Home banner: one featured screensaver at a time, with a strip of the
//  featured set underneath. Rotates every 8 seconds unless Reduce Motion is on.
//

import SwiftUI
import Combine

struct HeroView: View {

    let items: [Screensaver]

    @EnvironmentObject var apiManager: APIManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    @State private var hovered: UUID?

    private let timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    private var current: Screensaver? {
        items.isEmpty ? nil : items[index % items.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let item = current {
                banner(for: item)
                    .id(item.id)
                    .transition(.opacity)
            }

            if items.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CSTheme.Spacing.md) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { offset, saver in
                            Button {
                                withAnimation(.easeInOut(duration: 0.6)) { index = offset }
                            } label: {
                                FeaturedThumbnail(
                                    screensaver: saver,
                                    isHovered: hovered == saver.id,
                                    isActive: saver.id == current?.id
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { hovered = $0 ? saver.id : nil }
                            .accessibilityLabel("Show \(saver.name)")
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .animation(.easeInOut(duration: 0.8), value: index)
        .onReceive(timer) { _ in
            guard !reduceMotion, items.count > 1, apiManager.detailedScreensaver == nil else { return }
            index = (index + 1) % items.count
        }
    }

    // MARK: - Banner

    private func banner(for item: Screensaver) -> some View {
        ZStack(alignment: .bottomLeading) {
            ThumbnailView(item.thumbnailURL) { ScreensaverGradients.heroGradient(for: item) }
                .frame(maxWidth: .infinity)
                .frame(height: 300)

            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                Text("FEATURED")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.6))

                Text(item.name)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(details(for: item))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))

                HStack(spacing: 12) {
                    Button {
                        withAnimation(CSTheme.Animation.standard) {
                            apiManager.detailedScreensaver = item
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("View Screensaver")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(.plain)

                    Button {
                        apiManager.toggleLiked(item)
                    } label: {
                        Image(systemName: apiManager.isLiked(item) ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(apiManager.isLiked(item) ? .red : .white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(apiManager.isLiked(item) ? "Remove from favourites" : "Add to favourites")
                }
                .padding(.top, 4)
            }
            .padding(28)
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func details(for item: Screensaver) -> String {
        var parts = ["by \(item.author)", item.category.displayName]
        if let size = item.fileSize { parts.append(size) }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Featured Thumbnail

struct FeaturedThumbnail: View {

    let screensaver: Screensaver
    let isHovered: Bool
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CSTheme.Spacing.sm) {
            ZStack(alignment: .topLeading) {
                ThumbnailView(screensaver.thumbnailURL) { ScreensaverGradients.cardGradient(for: screensaver) }
                .frame(width: 180, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isActive ? Color.white : Color.white.opacity(0.08), lineWidth: isActive ? 2 : 1)
                )

                if screensaver.isNew {
                    Text("NEW")
                        .font(.system(size: 8, weight: .heavy))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(CSTheme.accent))
                        .foregroundColor(.white)
                        .padding(6)
                }
            }

            Text(screensaver.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isActive ? .white : CSTheme.textMuted)
                .lineLimit(1)
        }
        .frame(width: 180)
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}
