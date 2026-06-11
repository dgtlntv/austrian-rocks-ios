//
//  MapUnavailableOverlay.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct MapUnavailableOverlay: View {
    let message: String?
    let retry: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("map.unavailable.title")
                    .font(.headline)

                Text(message ?? String(localized: "map.unavailable.message"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(action: retry) {
                    Text("map.unavailable.retry")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 12)
            .padding(.horizontal)
            .padding(.bottom, 96)
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .contain)
    }
}
