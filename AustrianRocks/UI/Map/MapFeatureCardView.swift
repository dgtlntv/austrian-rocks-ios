//
//  MapFeatureCardView.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct MapFeatureCardView: View {
    let model: MapFeatureCardModel
    let onShowOnMap: () -> Void
    let onOpenDetail: () -> Void
    let onDirections: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverPhoto

            VStack(alignment: .leading, spacing: 14) {
                header
                stats
                warning
                guidebook
                parking
                actions
            }
            .padding()
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.22), radius: 16, y: 8)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var coverPhoto: some View {
        if let url = model.coverPhotoURL {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.clear.frame(height: 0)
                    case .empty:
                        ZStack {
                            Color(.systemGray5)
                            ProgressView()
                        }
                    @unknown default:
                        Color(.systemGray5)
                    }
                }
                .frame(height: 160)
                .clipped()

                closeButton
                    .padding(10)
                    .background(Circle().fill(Color.black.opacity(0.45)))
                    .foregroundColor(.white)
                    .padding(10)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            if model.coverPhotoURL == nil {
                closeButton
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var stats: some View {
        if hasStats {
            VStack(alignment: .leading, spacing: 8) {
                if let statsLine = statsLine {
                    Text(statsLine)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                MapFeatureCardGradeHistogramView(entries: model.gradeHistogram)
            }
        }
    }

    @ViewBuilder
    private var warning: some View {
        if let warning = model.warning {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(warning)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(10)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityLabel(Text("map.card.warning"))
            .accessibilityValue(Text(warning))
        }
    }

    @ViewBuilder
    private var guidebook: some View {
        if let guidebook = model.guidebook {
            LabelledLinkRow(
                label: String(localized: "map.card.guidebook"),
                title: guidebook.author.map { "\(guidebook.title) — \($0)" } ?? guidebook.title,
                url: guidebook.url
            )
        }
    }

    @ViewBuilder
    private var parking: some View {
        if let parking = model.parking {
            LabelledLinkRow(
                label: parking.name ?? String(localized: "map.poi_type.parking"),
                title: String(localized: "map.card.directions"),
                url: parking.url
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if model.kind == .poi {
                if model.canOpenDirections {
                    Button(action: onDirections) {
                        Label("map.card.directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appBrandColor)
                }
            } else {
                if model.bounds != nil {
                    Button(action: onShowOnMap) {
                        Label("map.card.show_on_map", systemImage: "scope")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appBrandColor)
                }

                Button(action: onOpenDetail) {
                    Text(model.detailAvailability.canOpenDetail ? String(localized: "map.card.details") : String(localized: "map.card.details_unavailable"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!model.detailAvailability.canOpenDetail)
            }
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .frame(width: 28, height: 28)
        }
        .accessibilityLabel(Text("map.card.close"))
    }

    private var subtitle: String? {
        switch model.kind {
        case .poi:
            return model.poiType.map { poiTypeName($0) }
        case .region, .cluster, .area:
            return nil
        }
    }

    private var hasStats: Bool {
        statsLine != nil || !model.gradeHistogram.isEmpty
    }

    private var statsLine: String? {
        var parts: [String] = []
        if let problemCount = model.problemCount {
            parts.append("\(problemCount) \(String(localized: "map.card.problems"))")
        }
        if let gradeMin = model.gradeMin, let gradeMax = model.gradeMax {
            parts.append("\(gradeMin) – \(gradeMax)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func poiTypeName(_ type: Poi.PoiType) -> String {
        switch type {
        case .parking:
            return String(localized: "map.poi_type.parking")
        case .trainStation:
            return String(localized: "map.poi_type.train_station")
        }
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
