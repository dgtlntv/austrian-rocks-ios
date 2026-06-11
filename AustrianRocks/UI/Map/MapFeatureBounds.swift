//
//  MapFeatureBounds.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import CoreLocation
import Foundation

struct MapFeatureBounds: Equatable {
    let southWest: CLLocationCoordinate2D
    let northEast: CLLocationCoordinate2D

    static func == (lhs: MapFeatureBounds, rhs: MapFeatureBounds) -> Bool {
        lhs.southWest.latitude == rhs.southWest.latitude &&
        lhs.southWest.longitude == rhs.southWest.longitude &&
        lhs.northEast.latitude == rhs.northEast.latitude &&
        lhs.northEast.longitude == rhs.northEast.longitude
    }

    var isValid: Bool {
        southWest.latitude.isFinite && southWest.longitude.isFinite &&
        northEast.latitude.isFinite && northEast.longitude.isFinite &&
        (-90...90).contains(southWest.latitude) && (-90...90).contains(northEast.latitude) &&
        (-180...180).contains(southWest.longitude) && (-180...180).contains(northEast.longitude) &&
        southWest.latitude <= northEast.latitude && southWest.longitude <= northEast.longitude
    }

    init?(southWestLat: Double?, southWestLon: Double?, northEastLat: Double?, northEastLon: Double?) {
        guard let southWestLat, let southWestLon, let northEastLat, let northEastLon else { return nil }
        let candidate = MapFeatureBounds(
            southWest: CLLocationCoordinate2D(latitude: southWestLat, longitude: southWestLon),
            northEast: CLLocationCoordinate2D(latitude: northEastLat, longitude: northEastLon)
        )
        guard candidate.isValid else { return nil }
        self = candidate
    }

    private init(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        self.southWest = southWest
        self.northEast = northEast
    }

    static func fromProperties(_ properties: [String: Any], preferMainCluster: Bool = false) -> MapFeatureBounds? {
        if preferMainCluster,
           let mainCluster = MapFeatureBounds(
            southWestLat: properties.doubleValue(for: "mainClusterSouthWestLat"),
            southWestLon: properties.doubleValue(for: "mainClusterSouthWestLon"),
            northEastLat: properties.doubleValue(for: "mainClusterNorthEastLat"),
            northEastLon: properties.doubleValue(for: "mainClusterNorthEastLon")
           ) {
            return mainCluster
        }

        return MapFeatureBounds(
            southWestLat: properties.doubleValue(for: "southWestLat"),
            southWestLon: properties.doubleValue(for: "southWestLon"),
            northEastLat: properties.doubleValue(for: "northEastLat"),
            northEastLon: properties.doubleValue(for: "northEastLon")
        )
    }
}
