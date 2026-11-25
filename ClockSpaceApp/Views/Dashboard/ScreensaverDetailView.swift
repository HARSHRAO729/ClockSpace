//
//  ScreensaverDetailView.swift
//  ClockSpace
//
//  Full-window detail for one screensaver: picture, everything the catalog
//  says about it, and the install controls in a floating bar.
//

import SwiftUI

struct ScreensaverDetailView: View {
    let screensaver: Screensaver
    @EnvironmentObject var apiManager: APIManager
    @ObservedObject private var manager = ScreensaverManager.shared

    private var installState: InstallState {
        if manager.isInstalling(screensaver) { return .installing }
        if manager.isInstalled(screensaver) { return .installed }
        return .ready
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            background
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.55), .black.opacity(0.92)],
                           startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 24) {
                infoPanel
                pillBar
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private func close() {
        withAnimation(CSTheme.Animation.standard) {
            apiManager.detailedScreensaver = nil
        }
    }

    // MARK: - Background

    private var background: some View {
        ThumbnailView(screensaver.thumbnailURL) { ScreensaverGradients.cardGradient(for: screensaver) }
    }

    // MARK: - Info

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(screensaver.name)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(metaLine)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            if !screensaver.description.isEmpty {
                Text(screensaver.description)
                    .font(CSTheme.Font.body)
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: 560, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !screensaver.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(screensaver.tags.prefix(6), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                }
            }

            if let source = screensaver.sourceURL, let url = URL(string: source) {
                Link(destination: url) {
                    Label("Project page", systemImage: "arrow.up.right.square")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(CSTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaLine: String {
        var parts = ["by \(screensaver.author)", screensaver.category.displayName]
        if let size = screensaver.fileSize { parts.append(size) }
        if let license = screensaver.license { parts.append(license) }
        if screensaver.appleSiliconOnly { parts.append("Apple Silicon only") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Floating bar

    private var pillBar: some View {
        HStack(spacing: 16) {
            Button(action: close) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction) // Esc
            .help("Back (Esc)")
            .accessibilityLabel("Back")

            Text(screensaver.name)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button {
                withAnimation(.spring()) { apiManager.toggleLiked(screensaver) }
            } label: {
                Image(systemName: apiManager.isLiked(screensaver) ? "heart.fill" : "heart")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(apiManager.isLiked(screensaver) ? .red : .white.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(apiManager.isLiked(screensaver) ? "Remove from favourites" : "Add to favourites")

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 28)

            installControls
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
        .background(Capsule().fill(Color.black.opacity(0.35)))
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }

    @ViewBuilder
    private var installControls: some View {
        switch installState {
        case .ready:
            Button {
                Task { await manager.install(screensaver) }
            } label: {
                Text("Install")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(CSTheme.accent))
            }
            .buttonStyle(.plain)
            .disabled(manager.isBusy)
            .opacity(manager.isBusy ? 0.5 : 1)

        case .installing:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                Text("Installing…")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.2)))

        case .installed:
            HStack(spacing: 8) {
                Button {
                    manager.openScreenSaverSettings()
                } label: {
                    Label("Open Settings", systemImage: "arrow.up.forward.app")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(CSTheme.surfaceElevated)
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation { manager.uninstall(screensaver) }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
                .help("Uninstall")
                .accessibilityLabel("Uninstall \(screensaver.name)")
            }
        }
    }
}
