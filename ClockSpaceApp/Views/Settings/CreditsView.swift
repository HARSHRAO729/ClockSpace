//
//  CreditsView.swift
//  ClockSpace
//
//  Honoring the creators of the open-source screensavers 
//  and libraries that make ClockSpace possible.
//

import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) var dismiss
    
    let contributors = [
        Contributor(name: "John Coates", work: "Aerial", url: "https://github.com/JohnCoates/Aerial"),
        Contributor(name: "Pedro Carrasco", work: "Brooklyn", url: "https://github.com/pedrocarrasco/Brooklyn"),
        Contributor(name: "Thomas So", work: "Flurry", url: "https://github.com/thomas-so/Flurry"),
        Contributor(name: "Google", work: "Firebase", url: "https://firebase.google.com"),
        Contributor(name: "The Community", work: "Dozens of open-source .saver files", url: "")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Credits & Curation")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 24)
                
                Text("ClockSpace is built on the shoulders of giants. We are grateful to the developers who open-source their beautiful screensavers for the world to enjoy.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(contributors) { contributor in
                            ContributorRow(contributor: contributor)
                        }
                    }
                }
                
                Spacer()
                
                Text("© 2026 ClockSpace Team. All rights reserved.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 30)
        }
    }
}

struct ContributorRow: View {
    let contributor: Contributor
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contributor.name)
                    .font(.system(size: 16, weight: .semibold))
                Text(contributor.work)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            if !contributor.url.isEmpty {
                Link(destination: URL(string: contributor.url)!) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct Contributor: Identifiable {
    let id = UUID()
    let name: String
    let work: String
    let url: String
}
