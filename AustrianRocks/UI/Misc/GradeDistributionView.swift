//
//  GradeDistributionView.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct GradeDistributionEntry: Equatable {
    let label: String
    let count: Int
}

/// The one grade-distribution visual: brand-red intensity tiers (mirroring the
/// web `histogramBarColor` brand-300/400/500 tiers) with explicit grade labels.
/// `.histogram` draws labeled bars; `.compactRow` draws the small per-level
/// squares used inside list rows.
struct GradeDistributionView: View {
    enum Style {
        case histogram
        case compactRow
    }

    let entries: [GradeDistributionEntry]
    var style: Style = .histogram
    var showsTitle = true

    private var maximumCount: Int {
        entries.map(\.count).max() ?? 0
    }

    private var accessibilitySummary: String {
        entries
            .filter { $0.count > 0 }
            .map { "\($0.label): \($0.count)" }
            .joined(separator: ", ")
    }

    var body: some View {
        if !entries.isEmpty, maximumCount > 0 {
            switch style {
            case .histogram:
                histogram
            case .compactRow:
                compactRow
            }
        }
    }

    private var histogram: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsTitle {
                Text("map.card.grade_distribution")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(entries, id: \.label) { entry in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barColor(for: entry.count))
                            .frame(height: barHeight(for: entry.count))
                            .frame(maxWidth: .infinity)
                            .accessibilityHidden(true)

                        Text(entry.label)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 72, alignment: .bottom)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(String(format: NSLocalizedString("map.card.grade_distribution_accessibility", comment: ""), accessibilitySummary)))
        }
    }

    private var compactRow: some View {
        HStack(spacing: 2) {
            ForEach(entries, id: \.label) { entry in
                Text(entry.label)
                    .font(.caption.weight(.medium))
                    .frame(width: 20, height: 20)
                    .foregroundColor(squareStyle(for: entry.count).foreground)
                    .background(squareStyle(for: entry.count).background)
                    .cornerRadius(4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(format: NSLocalizedString("map.card.grade_distribution_accessibility", comment: ""), accessibilitySummary)))
    }

    private func barHeight(for count: Int) -> CGFloat {
        guard maximumCount > 0, count > 0 else { return 2 }
        return max(4, CGFloat(count) / CGFloat(maximumCount) * 48)
    }

    private func barColor(for count: Int) -> Color {
        guard maximumCount > 0, count > 0 else { return Color(.systemGray5) }
        let ratio = CGFloat(count) / CGFloat(maximumCount)
        if ratio > 2.0 / 3.0 { return .appBrandColor }
        if ratio > 1.0 / 3.0 { return .appBrandColor.opacity(0.75) }
        return .appBrandColor.opacity(0.45)
    }

    // Text colour flips to white only on the fully saturated tier so every
    // tier stays readable in light and dark mode.
    private func squareStyle(for count: Int) -> (background: Color, foreground: Color) {
        switch count {
        case 0:
            return (Color(.systemGray5), .secondary)
        case 1...4:
            return (Color.appBrandColor.opacity(0.2), .primary)
        case 5...14:
            return (Color.appBrandColor.opacity(0.45), .primary)
        default:
            return (Color.appBrandColor, .white)
        }
    }
}
