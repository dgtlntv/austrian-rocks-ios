//
//  RegionCardView.swift
//  Austrian.rocks
//
//  Copyright © 2025 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct RegionCardView: View {
    let region: Region
    let width: CGFloat
    let height: CGFloat

    let shadow = Gradient(colors: [Color.black.opacity(0.2), Color.black.opacity(0.1)])

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(region.name)
                        .textCase(.uppercase)
                        .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 0)

                    if region.popular {
                        Text("area.tags.popular")
                            .font(.caption)
                            .textCase(.uppercase)
                            .opacity(0.9)
                    }
                }
            }
            .padding(8)
            .font(.headline.weight(.bold))
            .foregroundColor(Color.white)
            .frame(width: width, height: height)
            .background(
                ZStack {
                    CoverPhotoView(url: region.coverPhotoURL)
                    LinearGradient(gradient: shadow, startPoint: .top, endPoint: .bottom)
                }
            )
            .cornerRadius(8)
        }
    }
}
