//
//  ScreensaverCard.swift
//  ClockSpace
//
//  Elite screensaver card: 16pt radius, vibrant overlapping badge,
//  stark white title, muted gray metadata. Install button wired to
//  ScreensaverManager with Installing → Installed state transitions.
//

import SwiftUI
import AVKit
import Combine

// MARK: - Shared AVPlayer Cache

/// Manages a single reusable AVPlayer to prevent memory leaks.
/// Previous implementation created a new `AVPlayer(url:)` on every hover,
/// leaking 30-60 MB per interaction. This cache reuses one player instance.
private final class HoverPlayerCache: ObservableObject {
    static let shared = HoverPlayerCache()
    
    @Published private(set) var player: AVPlayer?
    @Published private(set) var activeURL: URL?
    
    private init() {}
    
    func play(url: URL) {
        if activeURL == url { return }
        
        // Tear down previous
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        
        let newPlayer = AVPlayer(url: url)
        newPlayer.isMuted = true
        newPlayer.play()
        
        self.player = newPlayer
        self.activeURL = url
    }
    
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        activeURL = nil
    }
}

struct ScreensaverCard: View {
       let screensaver: Screensaver
    @EnvironmentObject var apiManager: APIManager
    @StateObject private var manager = ScreensaverManager.shared
    @ObservedObject private var playerCache = HoverPlayerCache.shared
    @State private var isHovering: Bool = false
    @State private var thumbnailRefresh: UUID = UUID()
    
    var body: some View {
        ZStack {
            thumbnailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: 280)
        .frame(height: 186)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            if isHovering {
                VStack(spacing: 8) {
                    hoverInfoSection
                    
                    actionButton
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .topTrailing) {
            likeButton
                .padding(10)
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(isHovering)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .shadow(
            color: Color.black.opacity(isHovering ? 0.4 : 0.2),
            radius: isHovering ? 20 : 10,
            y: isHovering ? 12 : 4
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
            if hovering, let urlStr = screensaver.previewURL, let url = URL(string: urlStr) {
                playerCache.play(url: url)
            } else if !hovering {
                playerCache.stop()
            }
        }
        .onTapGesture {
            withAnimation(CSTheme.Animation.standard) {
                apiManager.detailedScreensaver = screensaver
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .id(thumbnailRefresh)
        .onReceive(NotificationCenter.default.publisher(for: .thumbnailDidLoad)) { _ in
            thumbnailRefresh = UUID()
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if manager.isInstalling(screensaver) {
            HStack {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                Text("Installing...")
                    .font(.system(size: 12, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.2)))
        } else if manager.isInstalled(screensaver) {
            HStack {
                Image(systemName: "checkmark")
                Text("Installed")
            }
            .font(.system(size: 12, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.green.opacity(0.2)))
        } else {
            Button(action: {
                Task {
                    await manager.installFromMarketplace(screensaver)
                }
            }) {
                Text("Apply")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Thumbnail (16pt radius enforced)
    
    private var thumbnailView: some View {
        ZStack(alignment: .topLeading) {
            // Live Preview (uses shared cached player)
            if isHovering,
               let urlStr = screensaver.previewURL,
               let url = URL(string: urlStr),
               let player = playerCache.player,
               playerCache.activeURL == url {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if let nsImage = ThumbnailLoader.loadImage(named: screensaver.thumbnailURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                fallbackThumbnail
            }
            
            // "NEW" Badge
            if screensaver.isNew {
                Text("NEW")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue))
                    .padding(CSTheme.Spacing.sm)
                    .offset(y: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: CSTheme.Radius.large,
                bottomLeadingRadius: CSTheme.Radius.large,
                bottomTrailingRadius: CSTheme.Radius.large,
                topTrailingRadius: CSTheme.Radius.large
            )
        )
    }
    
    
    // MARK: - Info Section
    
    private var hoverInfoSection: some View {
        VStack(alignment: .leading, spacing: CSTheme.Spacing.sm) {
            Text(screensaver.name)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
            Text("by \(screensaver.author)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 44) // keep clear of like button
    }
    
    private var likeButton: some View {
        Button(action: {
            apiManager.toggleLiked(screensaver)
        }) {
            Image(systemName: apiManager.isLiked(screensaver) ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(apiManager.isLiked(screensaver) ? .red : .white)
                .padding(10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Fallback Thumbnail (uses shared gradient palette)
    
    private var fallbackThumbnail: some View {
        ZStack {
            ScreensaverGradients.cardGradient(for: screensaver)
            VStack(spacing: 8) {
                Image(systemName: screensaver.category.iconName)
                    .font(.system(size: 32))
                Text(screensaver.category.rawValue.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
            }
            .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
