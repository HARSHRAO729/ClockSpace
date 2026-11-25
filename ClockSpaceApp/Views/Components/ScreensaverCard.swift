//
//  ScreensaverCard.swift
//  ClockSpace
//
//  A screensaver card. The name and author are always shown; hovering adds
//  Install and the favourite heart. Click, Return or Space opens the detail
//  view. VoiceOver reads it as one button with Install/Favourite actions.
//

import SwiftUI

struct ScreensaverCard: View {
    let screensaver: Screensaver
    @EnvironmentObject var apiManager: APIManager
    @ObservedObject private var manager = ScreensaverManager.shared
    @State private var isHovering = false

    private var isLiked: Bool { apiManager.isLiked(screensaver) }

    var body: some View {
        // The grid decides the card's size; the picture only fills it (an
        // aspect-fill image must never set the layout width, or cards overlap).
        Color.clear
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 186)
            .overlay { thumbnailView }
            .overlay(alignment: .bottom) { infoBar }
            .overlay(alignment: .topTrailing) {
                likeButton
                    .padding(8)
                    .opacity(isHovering || isLiked ? 1 : 0)
                    .allowsHitTesting(isHovering)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(isHovering ? 0.25 : 0.1), lineWidth: isHovering ? 1 : 0.5)
            )
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .shadow(color: .black.opacity(isHovering ? 0.4 : 0.2), radius: isHovering ? 18 : 8, y: isHovering ? 10 : 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHovering)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onHover { isHovering = $0 }
            .onTapGesture(perform: open)
            .focusable()
            .onKeyPress(.return) { open(); return .handled }
            .onKeyPress(.space) { open(); return .handled }
            // VoiceOver: one button per card, with the hover-only controls as actions.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(screensaver.name) by \(screensaver.author)")
            .accessibilityValue(statusText)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, open)
            .accessibilityAction(named: isLiked ? "Remove from favourites" : "Add to favourites") {
                apiManager.toggleLiked(screensaver)
            }
            .accessibilityAction(named: "Install") {
                guard !manager.isInstalled(screensaver), !manager.isBusy else { return }
                Task { await manager.install(screensaver) }
            }
    }

    private func open() {
        withAnimation(CSTheme.Animation.standard) {
            apiManager.detailedScreensaver = screensaver
        }
    }

    private var statusText: String {
        if manager.isInstalling(screensaver) { return "Installing" }
        if manager.isInstalled(screensaver) { return "Installed" }
        return screensaver.category.displayName
    }

    // MARK: - Name, author and hover actions

    private var infoBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(screensaver.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(screensaver.author)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            if isHovering {
                actionButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 28)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(isHovering ? 0.9 : 0.75)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    @ViewBuilder
    private var actionButton: some View {
        if manager.isInstalling(screensaver) {
            HStack {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                Text("Installing…")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.2)))
        } else if manager.isInstalled(screensaver) {
            Label("Installed", systemImage: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Capsule().fill(CSTheme.success.opacity(0.3)))
        } else {
            Button {
                Task { await manager.install(screensaver) }
            } label: {
                Text("Install")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)
            .disabled(manager.isBusy)
            .opacity(manager.isBusy ? 0.5 : 1)
        }
    }

    private var likeButton: some View {
        Button {
            apiManager.toggleLiked(screensaver)
        } label: {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(isLiked ? .red : .white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.black.opacity(0.35)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Picture

    private var thumbnailView: some View {
        ZStack(alignment: .topLeading) {
            ThumbnailView(screensaver.thumbnailURL) { fallbackThumbnail }

            if screensaver.isNew {
                Text("NEW")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(CSTheme.accent))
                    .padding(CSTheme.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fallbackThumbnail: some View {
        ZStack {
            ScreensaverGradients.cardGradient(for: screensaver)
            Image(systemName: screensaver.category.iconName)
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
