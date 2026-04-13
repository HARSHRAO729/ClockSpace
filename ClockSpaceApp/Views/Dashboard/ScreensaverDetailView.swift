//
//  ScreensaverDetailView.swift
//  ClockSpace
//
//  Immersive full-screen detail view for a screensaver.
//  Simulates a live preview and provides the main Set actions.
//

import SwiftUI
import AVKit

struct ScreensaverDetailView: View {
    let screensaver: Screensaver
    @EnvironmentObject var apiManager: APIManager
    @StateObject private var manager = ScreensaverManager.shared
    
    @State private var isAnimating = false
    @State private var player = AVPlayer()
    
    /// Derived install state
    private var installState: InstallState {
        if manager.activeID == screensaver.id {
            return .active
        } else if manager.isInstalling(screensaver) {
            return .installing
        } else if manager.isInstalled(screensaver) {
            return .installed
        } else {
            return .ready
        }
    }
    
    var body: some View {
        ZStack {
            // ── Live Preview Background ──
            livePreviewBackground
                .ignoresSafeArea()
            
            // ── Floating Action Pill (Bottom) ──
            VStack {
                Spacer()
                
                actionPill
                    .padding(.bottom, 40)
            }
        }
        .alert("Installation Error", isPresented: Binding(
            get: { manager.lastError != nil },
            set: { if !$0 { manager.lastError = nil } }
        )) {
            Button("OK") { manager.lastError = nil }
        } message: {
            Text(manager.lastError?.localizedDescription ?? "An unexpected error occurred.")
        }
    }
    
    // MARK: - Live Preview Background
    
    private var livePreviewBackground: some View {
        Group {
            if let urlStr = screensaver.previewURL, let url = URL(string: urlStr) {
                VideoPlayer(player: player)
                    .onAppear {
                        let item = AVPlayerItem(url: url)
                        player.replaceCurrentItem(with: item)
                        player.isMuted = true
                        player.play()
                        
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: item,
                            queue: .main
                        ) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
            } else {
                ZStack {
                    if screensaver.thumbnailURL != "placeholder",
                       let nsImage = NSImage(named: screensaver.thumbnailURL) ?? NSImage(contentsOfFile: "/Users/harshrao/ClockSpace/scratch/all_previews/" + screensaver.thumbnailURL) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .ignoresSafeArea()
                    } else {
                        // Base static gradient
                        gradient(for: screensaver)
                        
                        // Shifting Mesh Gradient Simulation
                        MeshGradientView(tintColor: screensaver.category.tintColor)
                        
                        // "Scanline" light sweep
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.05), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 200)
                            .offset(y: isAnimating ? boundsHeight : -boundsHeight)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Action Pill
    
    private var actionPill: some View {
        HStack(spacing: CSTheme.Spacing.xl) {
            
            // 1. Back Button & Title
            HStack(spacing: CSTheme.Spacing.md) {
                Button(action: {
                    withAnimation(CSTheme.Animation.standard) {
                        apiManager.detailedScreensaver = nil
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(screensaver.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                        Text(screensaver.author)
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(CSTheme.textTertiary)
                }
            }
            
            Spacer()
            
            // 2. Toolbar Actions
            Button(action: {
                withAnimation(.spring()) {
                    apiManager.toggleLiked(screensaver)
                }
            }) {
                Image(systemName: apiManager.isLiked(screensaver) ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(apiManager.isLiked(screensaver) ? .red : .white)
            }
            .buttonStyle(.plain)
            
            // 3. Set Wallpaper CTA
            installButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 40)
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
    
    // MARK: - Install Button (Shared Logic)
    
    @ViewBuilder
    private var installButton: some View {
        switch installState {
        case .ready:
            Button(action: {
                Task {
                    await manager.installFromMarketplace(screensaver)
                }
            }) {
                Text(screensaver.isPremium ? screensaver.formattedPrice : "Apply")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(screensaver.isPremium ? .black : .white)
                    .padding(.horizontal, CSTheme.Spacing.xl)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(screensaver.isPremium ? CSTheme.premiumGold : CSTheme.accent)
                    )
            }
            .buttonStyle(.plain)
            
        case .installing:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                
                Text("Installing...")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, CSTheme.Spacing.xl)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color.white.opacity(0.2)))
            
        case .installed:
            Button(action: {
                let saverName = screensaver.name.replacingOccurrences(of: " ", with: "-").lowercased()
                let saverPath = manager.screenSaversDirectory.appendingPathComponent("\(saverName).saver").path
                let success = manager.applyScreensaver(name: saverName, path: saverPath)
                if success {
                    manager.activeID = screensaver.id
                } else {
                    manager.lastError = ScreensaverInstallError.unknown("Failed to open System Settings.")
                }
            }) {
                Text("Open in Settings")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, CSTheme.Spacing.xl)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(CSTheme.surfaceElevated))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)

            
        case .active:
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                Text("Active")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(CSTheme.accent)
            .padding(.horizontal, CSTheme.Spacing.xl)
            .padding(.vertical, 14)
            .background(Capsule().fill(CSTheme.accent.opacity(0.12)))
            .overlay(Capsule().stroke(CSTheme.accent.opacity(0.3), lineWidth: 1))
        }
    }
    
    // MARK: - Gradient Helper
    
    private var boundsWidth: CGFloat {
        NSScreen.main?.frame.width ?? 1000
    }
    
    private var boundsHeight: CGFloat {
        NSScreen.main?.frame.height ?? 800
    }
    
    private func gradient(for saver: Screensaver) -> LinearGradient {
        let gradients: [LinearGradient] = [
            LinearGradient(colors: [Color(hex: 0x0F172A), Color(hex: 0x1E3A5F), Color(hex: 0x0F766E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x1A1A2E), Color(hex: 0x16213E), Color(hex: 0x0F3460)], startPoint: .top, endPoint: .bottom),
            LinearGradient(colors: [Color(hex: 0x2D1B69), Color(hex: 0x11998E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x0F0C29), Color(hex: 0x302B63), Color(hex: 0x24243E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x1F1C2C), Color(hex: 0x928DAB)], startPoint: .bottom, endPoint: .top),
            LinearGradient(colors: [Color(hex: 0x0D324D), Color(hex: 0x7F5A83)], startPoint: .topLeading, endPoint: .bottomTrailing),
        ]
        let index = abs(saver.name.hashValue) % gradients.count
        return gradients[index]
    }
}

// MARK: - Mesh Gradient Extracted Component

struct MeshGradientView: View {
    let tintColor: Color
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.black.opacity(0.1)))
                
                let baseColor = tintColor.opacity(0.15)
                let gradient = Gradient(colors: [baseColor, Color.clear])
                
                for i in 0..<3 {
                    let offset = Double(i)
                    let w = Double(size.width)
                    let h = Double(size.height)
                    
                    let x = w / 2.0 + cos(time * 0.5 + offset) * (w / 3.0)
                    let y = h / 2.0 + sin(time * 0.4 + offset) * (h / 3.0)
                    
                    let rect = CGRect(x: x - 200.0, y: y - 200.0, width: 400.0, height: 400.0)
                    let centerPoint = CGPoint(x: x, y: y)
                    
                    context.fill(Path(ellipseIn: rect), with: .radialGradient(
                        gradient,
                        center: centerPoint,
                        startRadius: 0,
                        endRadius: 200.0
                    ))
                }
            }
        }
    }
}
