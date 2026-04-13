//
//  ClockSpaceSaverContent.swift
//  ClockSpaceSaver
//
//  SwiftUI content view rendered as the actual screensaver.
//  A minimalist animated clock on a dark gradient background with floating particles.
//

import SwiftUI

/// The SwiftUI view hosted inside the screen saver.
struct ClockSpaceSaverContent: View {
    
    /// Whether rendering in the System Settings preview pane (smaller, reduced effects).
    let isPreview: Bool
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            ZStack {
                // ── Background ──
                backgroundLayer
                
                // ── Floating Particles ──
                if !isPreview {
                    ParticleField()
                }
                
                // ── Clock Face ──
                clockFace(date: context.date)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack {
            // Deep black base
            Color.black
            
            // Radial accent glow
            RadialGradient(
                colors: [
                    Color(red: 0.13, green: 0.77, blue: 0.37).opacity(0.08), // accent green
                    Color.clear
                ],
                center: .init(x: 0.3, y: 0.4),
                startRadius: 100,
                endRadius: 600
            )
            
            // Subtle blue glow
            RadialGradient(
                colors: [
                    Color(red: 0.2, green: 0.3, blue: 0.8).opacity(0.05),
                    Color.clear
                ],
                center: .init(x: 0.7, y: 0.6),
                startRadius: 80,
                endRadius: 500
            )
        }
    }
    
    // MARK: - Clock Face
    
    private func clockFace(date: Date) -> some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        let dateString = dateFormatter.string(from: date)
        
        return VStack(spacing: isPreview ? 8 : 20) {
            // Time display
            HStack(alignment: .firstTextBaseline, spacing: isPreview ? 2 : 4) {
                Text(String(format: "%02d", hour))
                    .font(.system(size: isPreview ? 48 : 120, weight: .ultraLight, design: .default))
                    .foregroundColor(.white)
                
                Text(":")
                    .font(.system(size: isPreview ? 40 : 100, weight: .ultraLight, design: .default))
                    .foregroundColor(.white.opacity(0.5))
                    .offset(y: isPreview ? -4 : -10)
                
                Text(String(format: "%02d", minute))
                    .font(.system(size: isPreview ? 48 : 120, weight: .ultraLight, design: .default))
                    .foregroundColor(.white)
                
                // Seconds — smaller, muted
                VStack {
                    Spacer()
                    Text(String(format: "%02d", second))
                        .font(.system(size: isPreview ? 16 : 36, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.bottom, isPreview ? 6 : 14)
                }
            }
            .monospacedDigit()
            
            // Date line
            Text(dateString)
                .font(.system(size: isPreview ? 10 : 18, weight: .medium, design: .default))
                .foregroundColor(.white.opacity(0.4))
                .tracking(isPreview ? 1 : 3)
                .textCase(.uppercase)
            
            // Subtle divider
            if !isPreview {
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.15), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 1)
                    .padding(.top, 8)
                
                // Branding
                Text("ClockSpace")
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.15))
                    .tracking(4)
                    .textCase(.uppercase)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Particle Field

/// Floating ambient particles for visual depth.
struct ParticleField: View {
    
    private let particleCount = 30
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<particleCount, id: \.self) { i in
                ParticleDot(
                    screenSize: geo.size,
                    seed: i
                )
            }
        }
    }
}

/// A single animated particle dot.
struct ParticleDot: View {
    
    let screenSize: CGSize
    let seed: Int
    
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    
    private var size: CGFloat {
        var rng = SeededRNG(seed: UInt64(seed))
        return CGFloat.random(in: 1...3, using: &rng)
    }
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .position(position)
            .opacity(opacity)
            .onAppear {
                // Randomize initial position
                var rng = SeededRNG(seed: UInt64(seed))
                position = CGPoint(
                    x: CGFloat.random(in: 0...screenSize.width, using: &rng),
                    y: CGFloat.random(in: 0...screenSize.height, using: &rng)
                )
                
                // Animate a slow drift + fade cycle
                let duration = Double.random(in: 8...20, using: &rng)
                let delay = Double.random(in: 0...5, using: &rng)
                
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    position = CGPoint(
                        x: CGFloat.random(in: 0...screenSize.width, using: &rng),
                        y: CGFloat.random(in: 0...screenSize.height, using: &rng)
                    )
                    opacity = Double.random(in: 0.1...0.5, using: &rng)
                }
            }
    }
}

// MARK: - Seeded RNG

/// A simple seeded random number generator for deterministic particle placement.
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed &+ 0x9E3779B97F4A7C15
    }
    
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }
}

/* Preview hidden for CLI build */
