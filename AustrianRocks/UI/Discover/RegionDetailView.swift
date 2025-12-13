//
//  RegionDetailView.swift
//  Austrian.rocks
//
//  Copyright © 2025 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct RegionDetailView: View {
    let region: Region
    @State private var clusters = [Cluster]()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Region header image
                ZStack(alignment: .bottomLeading) {
                    // Placeholder: Use region ID for cover image
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

                // Clusters section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Clusters")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if clusters.isEmpty {
                        Text("No clusters available")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(clusters) { cluster in
                            NavigationLink(destination: ClusterViewWithActionsheet(cluster: cluster)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(cluster.name)
                                            .font(.headline)

                                        Text("\(cluster.areas.count) areas")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(region.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadClusters()
        }
    }

    private func loadClusters() {
        clusters = region.clusters
    }
}
