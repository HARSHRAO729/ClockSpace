//
//  AppLogoView.swift
//  ClockSpace
//
//  The round ClockSpace logo in the navbar.
//

import SwiftUI
import AppKit

struct AppLogoView: View {
    var body: some View {
        // ClockSpace.png is a plain bundle resource, not an asset catalog image,
        // so it must be loaded through NSImage.
        Group {
            if let logo = NSImage(named: "ClockSpace") {
                Image(nsImage: logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "clock.fill")
                    .foregroundColor(.white)
            }
        }
        .frame(width: 38, height: 38)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
        .accessibilityHidden(true)
    }
}
