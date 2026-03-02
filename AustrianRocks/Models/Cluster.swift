//
//  Cluster.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 28/06/2024.
//  Copyright © 2024 Nicolas Mondollot. All rights reserved.
//

import UIKit
import SQLite

import CoreLocation

struct Cluster : Identifiable, Hashable {
    let id: Int
    let name: String
    let mainAreaId: Int
    let regionId: Int?
    let slug: String?
    let tags: [String]
    let published: Bool?

    var mainArea: Area {
        Area.load(id: mainAreaId) ?? areas.first!
    }

    var region: Region? {
        guard let regionId = regionId else { return nil }
        return Region.load(id: regionId)
    }

    var popular: Bool {
        tags.contains("popular")
    }

    func areasSortedByDistance(_ reference: Area?) -> [Area] {
        let area = reference ?? mainArea

        return areas.sorted {
            $0.center.distance(from: area.center) < $1.center.distance(from: area.center)
        }
    }
}

// MARK: SQLite
extension Cluster {
    static let id = Expression<Int>("id")
    static let name = Expression<String>("name")
    static let mainAreaId = Expression<Int>("main_area_id")
    static let regionId = Expression<Int?>("region_id")
    static let slug = Expression<String?>("slug")
    static let tags = Expression<String?>("tags")
    static let published = Expression<Bool?>("published")

    static func load(id: Int) -> Cluster? {

        let query = Table("clusters").filter(self.id == id)

        do {
            if let c = try SqliteStore.shared.db.pluck(query) {
                let allowedTags = ["popular"]
                let tags = c[tags]?.components(separatedBy: ",").filter{allowedTags.contains($0)}

                return Cluster(
                    id: id,
                    name: c[name],
                    mainAreaId: c[mainAreaId],
                    regionId: c[regionId],
                    slug: c[slug],
                    tags: tags ?? [],
                    published: c[published]
                )
            }

            return nil
        }
        catch {
            print (error)
            return nil
        }
    }
    
    var areas: [Area] {
        let areas = Table("areas")
            .filter(Area.clusterId == id)
            .order(Area.priority.asc)
        
        do {
            return try SqliteStore.shared.db.prepare(areas).map { area in
                Area.load(id: area[Area.id])
            }.compactMap{$0}
        }
        catch {
            print (error)
            return []
        }
    }
}
