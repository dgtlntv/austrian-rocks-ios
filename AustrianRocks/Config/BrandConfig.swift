//
//  BrandConfig.swift
//  Austrian.rocks
//
//  Copyright © 2025 Austrian.rocks. All rights reserved.
//

import Foundation
import SwiftUI

struct BrandConfig {
    static let name = "Austrian.rocks"
    static let slug = "austrian-rocks"

    struct Brand {
        // Brand color - currently using the existing AppGreen color
        // Update these values to change the app's brand color
        static let color = Color("AppGreen")

        // Alternative: Define custom color directly
        // static let color = Color(red: 0.396, green: 0.769, blue: 0.400)
    }

    struct Domains {
        static let main = "austrian.rocks"
        static let www = "www.austrian.rocks"
        static let assets = "assets.austrian.rocks"
    }

    struct Contact {
        static let email = "hello@austrian.rocks"
    }

    struct AppStore {
        // Intentionally absent until App Store release; setting this enables the rate/review link.
        static let appID: String? = nil

        static var reviewURL: URL? {
            guard let appID, !appID.isEmpty else { return nil }
            return URL(string: "https://itunes.apple.com/app/id\(appID)?action=write-review")
        }
    }

    struct Mapbox {
        static let account = "dgtlntv"
        static let styleID = "cmi0wnif6004t01r0araj0ts0"
        // TODO: create a dedicated dark-mode style; for now, fall back to the light style.
        static let darkStyleID = styleID
        static let problemsTilesetID = "95ifk802"
        static let problemsSourceLayer = "problems_8-85f5eq"

        static var styleURL: String {
            "mapbox://styles/\(account)/\(styleID)"
        }

        static var darkStyleURL: String {
            "mapbox://styles/\(account)/\(darkStyleID)"
        }

        static var problemsTilesetURL: String {
            "mapbox://\(account).\(problemsTilesetID)"
        }
    }

    struct Database {
        static let filename = "austrian-rocks"
    }
}
