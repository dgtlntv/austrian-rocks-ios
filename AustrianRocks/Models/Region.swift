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
    let slug: String?
    let mainClusterId: Int?
    let centerLat: Double?
    let centerLon: Double?
    let southWestLat: Double?
    let southWestLon: Double?
    let northEastLat: Double?
    let northEastLon: Double?
    let tags: [String]
    let published: Bool?
    let coverPhotoUrl: String?

    var popular: Bool {
        tags.contains("popular")
    }

    /// Validated remote cover photo URL, or nil when the export has no
    /// `cover_photo_url` column yet, the value is NULL, or it is not a safe
    /// HTTP(S) URL — all rendered as the placeholder.
    var coverPhotoURL: URL? {
        Self.coverPhotoURL(from: coverPhotoUrl)
    }

    static func coverPhotoURL(from rawValue: String?) -> URL? {
        guard let rawValue,
              let url = URL(string: rawValue),
              url.isHTTPOrHTTPS else { return nil }
        return url
    }

    var center: CLLocation? {
        guard let lat = centerLat, let lon = centerLon else { return nil }
        return CLLocation(latitude: lat, longitude: lon)
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
    static let slug = Expression<String?>("slug")
    static let mainClusterId = Expression<Int?>("main_cluster_id")
    static let centerLat = Expression<Double?>("center_lat")
    static let centerLon = Expression<Double?>("center_lon")
    static let southWestLat = Expression<Double?>("south_west_lat")
    static let southWestLon = Expression<Double?>("south_west_lon")
    static let northEastLat = Expression<Double?>("north_east_lat")
    static let northEastLon = Expression<Double?>("north_east_lon")
    static let tags = Expression<String?>("tags")
    static let published = Expression<Bool?>("published")
    // SQLite cover contract (0005-P6): nullable cover_photo_url TEXT holding
    // the same absolute HTTPS URL the map tile properties carry as
    // coverPhotoUrl. Read defensively — today's exports lack the column.
    static let coverPhotoUrl = Expression<String?>("cover_photo_url")

    static func load(id: Int, from db: Connection = SqliteStore.shared.db) -> Region? {
        let query = Table("regions").filter(self.id == id)

        do {
            if let r = try db.pluck(query) {
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
                    published: r[published],
                    coverPhotoUrl: (try? r.get(coverPhotoUrl)) ?? nil
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
