//
//  Region.swift
//  Austrian.rocks
//
//  Copyright © 2025 Austrian.rocks. All rights reserved.
//

import UIKit
import SQLite
import CoreLocation

struct Region: Identifiable, Hashable {
    let id: Int
    let name: String
    let slug: String
    let mainClusterId: Int?
    let centerLat: Double
    let centerLon: Double
    let southWestLat: Double
    let southWestLon: Double
    let northEastLat: Double
    let northEastLon: Double
    let tags: [String]
    let published: Bool

    var popular: Bool {
        tags.contains("popular")
    }

    var center: CLLocation {
        CLLocation(latitude: centerLat, longitude: centerLon)
    }

    var mainCluster: Cluster? {
        guard let mainClusterId = mainClusterId else { return nil }
        return Cluster.load(id: mainClusterId)
    }
}

// MARK: SQLite
extension Region {
    static let id = Expression<Int>("id")
    static let name = Expression<String>("name")
    static let slug = Expression<String>("slug")
    static let mainClusterId = Expression<Int?>("main_cluster_id")
    static let centerLat = Expression<Double>("center_lat")
    static let centerLon = Expression<Double>("center_lon")
    static let southWestLat = Expression<Double>("south_west_lat")
    static let southWestLon = Expression<Double>("south_west_lon")
    static let northEastLat = Expression<Double>("north_east_lat")
    static let northEastLon = Expression<Double>("north_east_lon")
    static let tags = Expression<String?>("tags")
    static let published = Expression<Bool>("published")

    static func load(id: Int) -> Region? {
        let query = Table("regions").filter(self.id == id)

        do {
            if let r = try SqliteStore.shared.db.pluck(query) {
                let allowedTags = ["popular"]
                let tags = r[tags]?.components(separatedBy: ",").filter{allowedTags.contains($0)}

                return Region(
                    id: id,
                    name: r[name],
                    slug: r[slug],
                    mainClusterId: r[mainClusterId],
                    centerLat: r[centerLat],
                    centerLon: r[centerLon],
                    southWestLat: r[southWestLat],
                    southWestLon: r[southWestLon],
                    northEastLat: r[northEastLat],
                    northEastLon: r[northEastLon],
                    tags: tags ?? [],
                    published: r[published]
                )
            }

            return nil
        } catch {
            print(error)
            return nil
        }
    }

    static var all: [Region] {
        let query = Table("regions")
            .filter(published == true)
            .order(name.asc)

        do {
            return try SqliteStore.shared.db.prepare(query).map { region in
                Region.load(id: region[id])
            }.compactMap{$0}
        } catch {
            print(error)
            return []
        }
    }

    var clusters: [Cluster] {
        let clusters = Table("clusters")
            .filter(Cluster.regionId == id)
            .filter(Cluster.published == true)
            .order(Cluster.name.asc)

        do {
            return try SqliteStore.shared.db.prepare(clusters).map { cluster in
                Cluster.load(id: cluster[Cluster.id])
            }.compactMap{$0}
        } catch {
            print(error)
            return []
        }
    }
}
