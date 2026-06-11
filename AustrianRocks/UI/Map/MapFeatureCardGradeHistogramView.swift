//
//  MapFeatureCardGradeHistogramView.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI

struct MapFeatureCardGradeHistogramView: View {
    let entries: [MapFeatureCardModel.GradeHistogramEntry]

    private var maximumCount: Int {
        entries.map(\.count).max() ?? 0
    }

    private var accessibilitySummary: String {
        entries
            .filter { $0.count > 0 }
            .map { "\($0.grade): \($0.count)" }
            .joined(separator: ", ")
    }

    var body: some View {
        if !entries.isEmpty, maximumCount > 0 {
            VStack(alignment: .leading, spacing: 8) {
                Text("map.card.grade_distribution")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(entries, id: \.grade) { entry in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(barColor(for: entry.count))
                                .frame(height: barHeight(for: entry.count))
                                .frame(maxWidth: .infinity)
                                .accessibilityHidden(true)

                            Text(entry.grade)
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
}
