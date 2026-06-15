//
//  MapFeatureSheetView.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI
import UIKit
import CoreLocation

/// Content of the map feature bottom card. Built like the problem card — plain
/// transparent content over the sheet's frosted material, no `List`/
/// `NavigationStack` (those paint opaque backgrounds). Region/cluster/area show
/// a compact "quick info" summary from the tile properties with a "More
/// details" link to the full Discover page; POIs show a directions card.
/// Driven by `MapState.selectedMapFeatureCard` so tapping a different feature
/// swaps the content in place without a dismiss/present cycle.
struct MapFeatureSheetView: View {
    /// Initial fallback while the feature card measures its rendered content.
    static let compactDetentHeight: CGFloat = 300
    static let compactMinDetentHeight: CGFloat = 200
    static var compactMaxDetentHeight: CGFloat {
        min(350, UIScreen.main.bounds.height * 0.44)
    }
    /// Small allowance for the system grabber/top chrome. The sheet already
    /// accounts for bottom safe area, so keep this tight to avoid a hollow
    /// footer in content-hugging cards.
    static let compactContentChromePadding: CGFloat = 8

    let isExpanded: Bool
    let onContentHeightChange: (CGFloat) -> Void

    init(isExpanded: Bool = false, onContentHeightChange: @escaping (CGFloat) -> Void = { _ in }) {
        self.isExpanded = isExpanded
        self.onContentHeightChange = onContentHeightChange
    }

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SystemMaterialBackground().ignoresSafeArea())
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
            MapFeatureQuickInfoView(
                card: card,
                isExpanded: isExpanded,
                onContentHeightChange: onContentHeightChange
            )
        }
    }
}

/// Compact, transparent quick-info card for a region/cluster/area, modeled on
/// the problem card. Renders purely from tile properties (no SQLite needed);
/// "More details" forwards to the full Discover page when it exists.
private struct MapFeatureQuickInfoView: View {
    let card: MapFeatureCardModel
    let isExpanded: Bool
    let onContentHeightChange: (CGFloat) -> Void

    @Environment(AppState.self) private var appState: AppState
    @Environment(MapState.self) private var mapState: MapState

    // Bumped to clear the grade chart's bar selection when the user taps
    // anywhere in the card outside the bars.
    @State private var gradeResetToken = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Full-bleed cover at the top, like the problem card's topo
                // image (regions carry covers; other kinds simply omit it).
                if let coverURL = card.coverPhotoURL {
                    CoverPhotoView(url: coverURL)
                        .frame(height: 170)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }

                VStack(alignment: .leading, spacing: 16) {
                    header
                    actions

                    if !card.gradeDistributionEntries.isEmpty {
                        GradeDistributionView(
                            entries: card.gradeDistributionEntries,
                            resetSelectionToken: gradeResetToken
                        )
                    }
                    if let warning = card.warning {
                        warningRow(warning)
                    }
                    links
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 4)
                .padding(.top, card.coverPhotoURL == nil ? 20 : 0)
                // Tapping the card outside the grade bars clears the selection.
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { gradeResetToken += 1 }
                )
            }
            .readHeight(onContentHeightChange)
        }
        .scrollDisabled(!isExpanded)
    }

    // Mirrors ProblemInfoView's title row: name on the left, grade on the
    // right of the same line, same font/weight/color.
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(card.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .truncationMode(.middle)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.5)

                    Text("· \(kindLabel)")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .lineLimit(1)

                Spacer()

                if let gradeMin = card.gradeMin, let gradeMax = card.gradeMax {
                    Text("\(gradeMin) – \(gradeMax)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }

            if let problemCount = card.problemCount {
                Text("\(problemCount) \(String(localized: "map.card.problems"))")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var kindLabel: String {
        switch card.kind {
        case .region:
            return String(localized: "map.card.kind.region")
        case .cluster:
            return String(localized: "map.card.kind.cluster")
        case .area:
            return String(localized: "map.card.kind.area")
        case .poi:
            return ""
        }
    }

    // Same pill buttons as ProblemActionButtonsView (adaptive glass on iOS 26,
    // bordered Pill below), in a horizontal scroll.
    private var actions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 12) {
                if card.bounds != nil {
                    Button {
                        mapState.fitSelectedMapFeatureOnMap()
                    } label: {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "scope")
                            Text("map.card.show_on_map")
                        }
                        .adaptivePillPadding()
                    }
                    .adaptivePillStyle()
                }

                if card.detailAvailability.canOpenDetail, let route = discoverRoute {
                    Button {
                        openInDiscover(route)
                    } label: {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "arrow.up.forward.square")
                            Text("map.card.more_details")
                        }
                        .adaptivePillPadding()
                    }
                    .adaptivePillStyle()
                }
            }
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private var links: some View {
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

    private func warningRow(_ warning: String) -> some View {
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

    private var discoverRoute: DiscoverRoute? {
        switch card.kind {
        case .region: return .region(card.id)
        case .cluster: return .cluster(card.id)
        case .area: return .area(card.id)
        case .poi: return nil
        }
    }

    private func openInDiscover(_ route: DiscoverRoute) {
        appState.discoverRoute = route
        appState.tab = .discover
        mapState.dismissMapFeatureCard()
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

private struct SystemMaterialBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: .systemMaterial)
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func readHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: HeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self, perform: onChange)
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
