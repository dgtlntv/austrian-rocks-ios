//
//  MapFeatureCardModel.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import Foundation
import CoreLocation

struct MapSafeURL {
    static func httpURL(from value: Any?) -> URL? {
        guard let string = value as? String, let url = URL(string: string), url.isHTTPOrHTTPS else { return nil }
        return url
    }
}

struct MapFeatureCardModel: Equatable, Identifiable {
    enum Kind: Equatable {
        case region
        case cluster
        case area
        case poi
    }

    struct Guidebook: Equatable {
        let title: String
        let author: String?
        let url: URL
    }

    struct Parking: Equatable {
        let name: String?
        let url: URL
    }

    struct GradeHistogramEntry: Equatable {
        let grade: String
        let count: Int
    }

    struct DetailAvailability: Equatable {
        let canOpenDetail: Bool
    }

    typealias DetailAvailabilityResolver = (Kind, Int) -> Bool

    let kind: Kind
    let id: Int
    let title: String
    let problemCount: Int?
    let gradeMin: String?
    let gradeMax: String?
    let gradeHistogram: [GradeHistogramEntry]
    let coverPhotoURL: URL?
    let warning: String?
    let guidebook: Guidebook?
    let parking: Parking?
    let bounds: MapFeatureBounds?
    let poiType: Poi.PoiType?
    let googleURL: URL?
    let detailAvailability: DetailAvailability

    static func make(
        kind: Kind,
        properties: [String: Any],
        localeIdentifier: String = Locale.current.language.languageCode?.identifier ?? "de",
        detailAvailabilityResolver: DetailAvailabilityResolver? = nil
    ) -> MapFeatureCardModel? {
        let idKey: String
        switch kind {
        case .region: idKey = MapLayerContract.Properties.regionId
        case .cluster: idKey = MapLayerContract.Properties.clusterId
        case .area: idKey = MapLayerContract.Properties.areaId
        case .poi: idKey = MapLayerContract.Properties.poiId
        }

        guard let id = properties.intValue(for: idKey) else { return nil }

        let title = localizedText(base: properties.stringValue(for: "name"), english: properties.stringValue(for: "nameEn"), localeIdentifier: localeIdentifier)
        let warning = localizedText(base: properties.stringValue(for: "warning"), english: properties.stringValue(for: "warningEn"), localeIdentifier: localeIdentifier).nilIfBlank
        let guidebook = guidebook(from: properties)
        let parking = parking(from: properties)
        let resolver = detailAvailabilityResolver ?? defaultDetailAvailabilityResolver
        let hasDetail: Bool = {
            switch kind {
            case .region, .cluster, .area:
                return resolver(kind, id)
            case .poi:
                return false
            }
        }()

        return MapFeatureCardModel(
            kind: kind,
            id: id,
            title: title,
            problemCount: properties.intValue(for: "problemCount"),
            gradeMin: properties.stringValue(for: "gradeMin"),
            gradeMax: properties.stringValue(for: "gradeMax"),
            gradeHistogram: histogramEntries(from: properties.stringValue(for: "gradeHistogramJson")),
            coverPhotoURL: MapSafeURL.httpURL(from: properties["coverPhotoUrl"]),
            warning: warning,
            guidebook: guidebook,
            parking: parking,
            bounds: MapFeatureBounds.fromProperties(properties, preferMainCluster: kind == .region),
            poiType: poiType(from: properties.stringValue(for: "poiType")),
            googleURL: MapSafeURL.httpURL(from: properties["googleUrl"]),
            detailAvailability: DetailAvailability(canOpenDetail: hasDetail)
        )
    }

    private static func localizedText(base: String?, english: String?, localeIdentifier: String) -> String {
        if localeIdentifier == "en", let english = english?.nilIfBlank {
            return english
        }
        return base?.nilIfBlank ?? ""
    }

    private static func guidebook(from properties: [String: Any]) -> Guidebook? {
        guard let url = MapSafeURL.httpURL(from: properties["guidebookUrl"]),
              let title = properties.stringValue(for: "guidebookTitle")?.nilIfBlank else { return nil }
        return Guidebook(title: title, author: properties.stringValue(for: "guidebookAuthor")?.nilIfBlank, url: url)
    }

    private static func parking(from properties: [String: Any]) -> Parking? {
        guard let url = MapSafeURL.httpURL(from: properties["parkingGoogleUrl"]) else { return nil }
        return Parking(name: properties.stringValue(for: "parkingName")?.nilIfBlank, url: url)
    }

    private static func poiType(from value: String?) -> Poi.PoiType? {
        switch value {
        case "parking": return .parking
        case "train_station": return .trainStation
        default: return nil
        }
    }

    private static func histogramEntries(from json: String?) -> [GradeHistogramEntry] {
        guard let data = json?.data(using: .utf8),
              let counts = try? JSONDecoder().decode([String: Int].self, from: data),
              !counts.isEmpty else { return [] }

        let scale = (1...9).flatMap { level in ["a", "b", "c"].map { "\(level)\($0)" } }
        guard counts.allSatisfy({ scale.contains($0.key) && $0.value > 0 }) else { return [] }

        guard var first = scale.firstIndex(where: { counts[$0] != nil }),
              var last = scale.lastIndex(where: { counts[$0] != nil }) else { return [] }

        while last - first + 1 < 5 && (first > 0 || last < scale.count - 1) {
            if last < scale.count - 1 { last += 1 } else { first -= 1 }
        }

        return scale[first...last].map { GradeHistogramEntry(grade: $0, count: counts[$0] ?? 0) }
    }

    private static let defaultDetailAvailabilityResolver: DetailAvailabilityResolver = { kind, id in
        switch kind {
        case .region:
            return Region.load(id: id) != nil
        case .cluster:
            return Cluster.load(id: id) != nil
        case .area:
            return Area.load(id: id) != nil
        case .poi:
            return false
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    func stringValue(for key: String) -> String? {
        if let string = self[key] as? String { return string }
        if let number = self[key] as? NSNumber { return number.stringValue }
        return nil
    }

    func intValue(for key: String) -> Int? {
        if let int = self[key] as? Int { return int }
        if let number = self[key] as? NSNumber { return number.intValue }
        if let string = self[key] as? String { return Int(string) }
        return nil
    }

    func doubleValue(for key: String) -> Double? {
        if let double = self[key] as? Double { return double }
        if let number = self[key] as? NSNumber { return number.doubleValue }
        if let string = self[key] as? String { return Double(string) }
        return nil
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
