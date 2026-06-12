//
//  CoverPhotoView.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI

/// Shared remote cover photo: loads the given URL through an on-disk
/// URLCache-backed session and shows a branded placeholder while loading or
/// when no URL exists. Covers are managed in Rails only, never bundled.
struct CoverPhotoView: View {
    let url: URL?

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Color.clear
                    .overlay(
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    )
                    .clipped()
            } else {
                placeholder
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    BrandConfig.Brand.color.opacity(0.35),
                    Color(.systemGray5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image("nophoto")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(Text("cover.photo.placeholder"))
    }

    private func loadImage() async {
        image = nil
        guard let url else { return }

        do {
            let (data, _) = try await Self.session.data(for: URLRequest(url: url))
            guard !Task.isCancelled else { return }
            image = UIImage(data: data)
        } catch {
            // Placeholder stays visible on failure.
        }
    }

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        let cacheDirectory = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("cover-photos", isDirectory: true)
        configuration.urlCache = URLCache(
            memoryCapacity: 8 * 1024 * 1024,
            diskCapacity: 64 * 1024 * 1024,
            directory: cacheDirectory
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }()
}
