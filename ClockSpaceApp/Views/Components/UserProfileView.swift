//
//  UserProfileView.swift
//  ClockSpace
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // Logo Image
        Image("ClockSpace")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 38, height: 38)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            UserProfileView()
        }
    }
}
