//
//  RegionDetailView.swift
//  Austrian.rocks
//
//  Copyright © 2025 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct RegionDetailView: View {
    let region: Region
    // Set when presented as a map bottom card: folds the tile-property card
    // data (stats, show-on-map CTA, histogram, warning, links) into the page.
    var mapCard: MapFeatureCardModel? = nil

    @Environment(\.discoverRouter) private var router

    @State private var clusters: [Cluster] = []

    var body: some View {
        List {
            if let mapCard {
                MapFeatureCardHeaderSection(card: mapCard)
            }

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
            CoverPhotoView(url: region.coverPhotoURL)
                .frame(height: 200)

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
        Section(header: Text("discover.region.clusters").font(.title2).fontWeight(.bold)) {
            if clusters.isEmpty {
                Text("discover.region.no_clusters")
                    .foregroundColor(.secondary)
            } else {
                ForEach(clusters) { cluster in
                    clusterRow(cluster)
                }
            }
        }
    }

    // Router-aware like ClusterDetailView.areaRow, so cluster rows work both
    // inside the Discover NavigationStack and when region details are shown
    // as a sheet from the map (no navigationDestination in that context).
    @ViewBuilder
    private func clusterRow(_ cluster: Cluster) -> some View {
        let label = HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(cluster.name)
                    .font(.headline)

                Text(String(format: NSLocalizedString("discover.cluster.areas_count", comment: ""), cluster.areas.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }

        if router != nil {
            NavigationLink(value: DiscoverRoute.cluster(cluster.id)) {
                label
            }
        } else {
            NavigationLink {
                ClusterDetailView(cluster: cluster)
            } label: {
                label
            }
        }
    }

    private func loadClusters() {
        clusters = region.clusters
    }
}
