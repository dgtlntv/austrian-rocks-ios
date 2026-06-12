//
//  ClusterDetailView.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct ClusterDetailView: View {
    let cluster: Cluster
    // Set when presented as a map bottom card: folds the tile-property card
    // data (stats, show-on-map CTA, histogram, warning, links) into the page.
    var mapCard: MapFeatureCardModel? = nil

    @Environment(\.discoverRouter) private var router

    @State private var areas: [Area] = []
    @State private var presentDownloadSheet = false

    private var clusterDownloader: ClusterDownloader {
        ClusterDownloader(cluster: cluster, mainArea: cluster.mainArea)
    }

    var body: some View {
        List {
            if let mapCard {
                MapFeatureCardHeaderSection(card: mapCard)
            }

            Section(header: Text("discover.cluster.areas")) {
                if areas.isEmpty {
                    Text("discover.cluster.no_areas")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(areas) { area in
                        areaRow(area)
                    }
                }
            }
        }
        .navigationTitle(cluster.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentDownloadSheet = true
                } label: {
                    Image(systemName: "icloud.and.arrow.down")
                }
                .accessibilityLabel(Text("download.cluster.download"))
            }
        }
        .sheet(isPresented: $presentDownloadSheet) {
            ClusterViewWithActionsheet(clusterDownloader: clusterDownloader)
                .presentationDetents([.medium, .large])
        }
        .task {
            areas = cluster.areas
        }
    }

    @ViewBuilder
    private func areaRow(_ area: Area) -> some View {
        let label = HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(area.name)
                    .font(.headline)

                Text(String(format: NSLocalizedString("discover.cluster.problems_count", comment: ""), area.problemsCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }

        if router != nil {
            NavigationLink(value: DiscoverRoute.area(area.id)) {
                label
            }
        } else {
            NavigationLink {
                AreaView(area: area, linkToMap: true)
            } label: {
                label
            }
        }
    }
}
