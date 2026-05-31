//
//  RegionsListView.swift
//  Austrian.rocks
//
//  Copyright © 2025 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct RegionsListView: View {
    @State private var regions = [Region]()
    @State private var searchText = ""

    var filteredRegions: [Region] {
        if searchText.isEmpty {
            return regions
        }
        return regions.filter { region in
            region.name.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredRegions) { region in
                    NavigationLink(destination: RegionDetailView(region: region)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(region.name)
                                    .font(.headline)

                                HStack {
                                    if region.popular {
                                        Text("area.tags.popular")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Text(String(format: NSLocalizedString("discover.regions.clusters", comment: ""), region.clusters.count))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("discover.regions.title")
            .searchable(text: $searchText, prompt: "discover.search_prompt")
            .onAppear {
                loadRegions()
            }
        }
    }

    private func loadRegions() {
        regions = Region.all
    }
}
