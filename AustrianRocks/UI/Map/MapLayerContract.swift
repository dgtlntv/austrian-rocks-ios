//
//  MapLayerContract.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

enum MapLayerContract {
    static let sourceId = "austrian-rocks"

    enum Layers {
        static let problems = "problems"
        static let boulders = "boulders"
        static let areas = "areas"
        static let areaHulls = "areas-hulls"
        static let clusters = "clusters"
        static let clusterHulls = "cluster-hulls"
        static let regions = "regions"
        static let regionHulls = "region-hulls"
        static let pois = "pois"
    }

    enum SelectedLayers {
        static let problems = "problems-selected"
        static let areas = "areas-selected"
        static let clusters = "clusters-selected"
        static let regions = "regions-selected"
        static let pois = "pois-selected"
    }

    enum Properties {
        static let problemId = "problemId"
        static let areaId = "areaId"
        static let clusterId = "clusterId"
        static let regionId = "regionId"
        static let poiId = "poiId"
    }

    static let clearedSentinel = -1

    /// Austria coverage bounds declared by the shared style's raster/vector
    /// sources (`[9.34, 46.281, 17.345, 49.332]`); the camera is constrained
    /// to this area.
    enum AustriaBounds {
        static let southWestLatitude = 46.281
        static let southWestLongitude = 9.34
        static let northEastLatitude = 49.332
        static let northEastLongitude = 17.345
    }
}
