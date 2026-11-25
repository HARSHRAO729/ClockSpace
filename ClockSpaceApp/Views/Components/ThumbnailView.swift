//
//  ThumbnailView.swift
//  ClockSpace
//
//  A screensaver picture that fills whatever frame it is given. Shows the
//  fallback until the image is ready; a cached image appears with no flash.
//

import SwiftUI

struct ThumbnailView<Fallback: View>: View {
    let urlString: String
    let fallback: Fallback

    @State private var image: CGImage?

    init(_ urlString: String, @ViewBuilder fallback: () -> Fallback) {
        self.urlString = urlString
        self.fallback = fallback()
        _image = State(initialValue: ImagePipeline.shared.cachedImage(for: urlString))
    }

    var body: some View {
        // The image fills the frame but never decides its size.
        Color.clear
            .overlay {
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    fallback
                }
            }
            .clipped()
            .task(id: urlString) {
                let loaded = await ImagePipeline.shared.image(for: urlString)
                if loaded != nil { image = loaded }
            }
    }
}
