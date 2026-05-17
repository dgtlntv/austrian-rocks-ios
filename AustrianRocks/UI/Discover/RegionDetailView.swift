//
//  RegionDetailView.swift
//  Austrian.rocks
//
//  Copyright © 2025 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct RegionDetailView: View {
    let region: Region
    @State private var clusters: [Cluster] = []

    var body: some View {
        List {
            Section {
                headerImage
            }

            clustersList
        }
        .navigationTitle(region.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadClusters()
        }
    }

    var headerImage: some View {
        ZStack(alignment: .bottomLeading) {
            Image("region-cover-\(region.id)")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()

            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 200)

            VStack(alignment: .leading) {
                Text(region.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 10)

                if region.popular {
                    Text("area.tags.popular")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                        .opacity(0.9)
                }
            }
            .padding()
        }
        .listRowInsets(EdgeInsets())
    }

    var clustersList: some View {
        Section(header: Text("Clusters").font(.title2).fontWeight(.bold)) {
            if clusters.isEmpty {
                Text("No clusters available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(clusters) { cluster in
                    NavigationLink(value: DiscoverRoute.cluster(cluster.id)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cluster.name)
                                    .font(.headline)

                                Text("\(cluster.areas.count) areas")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func loadClusters() {
        clusters = region.clusters
    }
}
