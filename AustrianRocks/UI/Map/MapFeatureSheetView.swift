//
//  MapFeatureSheetView.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI
import UIKit
import CoreLocation

/// Content of the map feature bottom card: region/cluster/area selections show
/// the existing detail views (with a card-header section folded in), POIs show
/// a compact directions card. Driven by `MapState.selectedMapFeatureCard` so a
/// tap on a different feature swaps the content in place without a
/// dismiss/present cycle.
struct MapFeatureSheetView: View {
    /// Compact detent: tall enough for grabber + title bar + stats + the
    /// show-on-map CTA while keeping most of the map visible behind.
    static let compactDetentHeight: CGFloat = 300

    @Environment(MapState.self) private var mapState: MapState

    // Keeps the last card alive while the sheet animates out after the
    // selection is cleared, so the content never blanks mid-dismissal.
    @State private var lastCard: MapFeatureCardModel? = nil

    private var card: MapFeatureCardModel? {
        mapState.selectedMapFeatureCard ?? lastCard
    }

    var body: some View {
        Group {
            if let card {
                content(for: card)
            }
        }
        .onAppear {
            if let card = mapState.selectedMapFeatureCard {
                lastCard = card
            }
        }
        .onChange(of: mapState.selectedMapFeatureCard) { _, newValue in
            if let newValue {
                lastCard = newValue
            }
        }
    }

    @ViewBuilder
    private func content(for card: MapFeatureCardModel) -> some View {
        switch card.kind {
        case .poi:
            PoiCardView(card: card)
        case .region, .cluster, .area:
            NavigationStack {
                detail(for: card)
            }
        }
    }

    @ViewBuilder
    private func detail(for card: MapFeatureCardModel) -> some View {
        switch card.kind {
        case .region:
            if let region = Region.load(id: card.id) {
                RegionDetailView(region: region, mapCard: card)
            } else {
                MapFeatureFallbackDetailView(card: card)
            }
        case .cluster:
            if let cluster = Cluster.load(id: card.id) {
                ClusterDetailView(cluster: cluster, mapCard: card)
            } else {
                MapFeatureFallbackDetailView(card: card)
            }
        case .area:
            if let area = Area.load(id: card.id) {
                AreaView(area: area, linkToMap: true, mapCard: card)
            } else {
                MapFeatureFallbackDetailView(card: card)
            }
        case .poi:
            EmptyView()
        }
    }
}

/// Tile-property card content folded into the detail views: stats, show-on-map
/// CTA, grade histogram, warning, and guidebook/parking links. The CTA sits
/// first so it is visible and tappable at the compact detent.
struct MapFeatureCardHeaderSection: View {
    let card: MapFeatureCardModel
    // Area pages render their own grade distribution and warning from SQLite,
    // so they opt out here to avoid showing the same data twice.
    var showsHistogram = true
    var showsWarning = true

    @Environment(MapState.self) private var mapState: MapState

    var body: some View {
        Section {
            if let statsLine = card.statsLine {
                Text(statsLine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if card.bounds != nil {
                Button {
                    mapState.fitSelectedMapFeatureOnMap()
                } label: {
                    Label("map.card.show_on_map", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appBrandColor)
            }

            if showsHistogram, !card.gradeDistributionEntries.isEmpty {
                GradeDistributionView(entries: card.gradeDistributionEntries)
                    .padding(.vertical, 4)
            }

            if showsWarning, let warning = card.warning {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .accessibilityLabel(Text("map.card.warning"))
                .accessibilityValue(Text(warning))
            }

            if let guidebook = card.guidebook {
                LabelledLinkRow(
                    label: String(localized: "map.card.guidebook"),
                    title: guidebook.author.map { "\(guidebook.title) — \($0)" } ?? guidebook.title,
                    url: guidebook.url
                )
            }

            if let parking = card.parking {
                LabelledLinkRow(
                    label: parking.name ?? String(localized: "map.poi_type.parking"),
                    title: String(localized: "map.card.directions"),
                    url: parking.url
                )
            }
        }
    }
}

/// Shown when the tile feature has no matching SQLite row (offline database
/// missing or out of date): the tile-property card data still renders safely.
private struct MapFeatureFallbackDetailView: View {
    let card: MapFeatureCardModel

    var body: some View {
        List {
            MapFeatureCardHeaderSection(card: card)

            Section {
                Text("map.card.details_unavailable")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(card.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Compact bottom card for POI taps: name, type, and directions actions.
/// Replaces the old alert-based directions chooser for map POIs.
private struct PoiCardView: View {
    let card: MapFeatureCardModel

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let typeName = card.localizedPoiTypeName {
                    Text(typeName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if card.canOpenDirections, let googleURL = card.googleURL {
                Button {
                    openURL(googleURL)
                } label: {
                    Label("map.card.directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appBrandColor)
            }

            if let coordinate = card.coordinate {
                HStack(spacing: 10) {
                    Button {
                        openAppleMaps(coordinate: coordinate, name: card.title)
                    } label: {
                        Text(verbatim: "Apple Maps")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if canOpenWaze {
                        Button {
                            openWaze(coordinate: coordinate)
                        } label: {
                            Text(verbatim: "Waze")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .padding(.top, 8) // room for the sheet grabber
    }

    private func openAppleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let urlString = "http://maps.apple.com/?q=\(name)&ll=\(coordinate.latitude),\(coordinate.longitude)"
        if let encoded = urlString.stringByAddingPercentEncodingForRFC3986(), let url = URL(string: encoded) {
            openURL(url)
        }
    }

    private func openWaze(coordinate: CLLocationCoordinate2D) {
        if let url = URL(string: "waze://?ll=\(coordinate.latitude),\(coordinate.longitude)&navigate=yes") {
            openURL(url)
        }
    }

    private var canOpenWaze: Bool {
        guard let url = URL(string: "waze://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

private struct LabelledLinkRow: View {
    let label: String
    let title: String
    let url: URL

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(label + ":")
                .font(.subheadline.weight(.semibold))
            Link(title, destination: url)
                .font(.subheadline)
                .foregroundColor(.appBrandColor)
        }
    }
}
