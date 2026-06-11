//
//  MapTileManifest.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import Foundation

struct MapTileManifest: Codable, Equatable {
    let version: String
    let pmtilesUrl: URL
    let spriteUrl: URL
    let styles: Styles
    let publishedAt: String

    struct Styles: Codable, Equatable {
        let light: URL?
        let dark: URL?
    }

    enum Error: Swift.Error, Equatable, LocalizedError {
        case invalidURL(field: String)
        case missingStyle(choice: MapStyleChoice)

        var errorDescription: String? {
            switch self {
            case .invalidURL(let field):
                return "Invalid map tile URL for \(field)."
            case .missingStyle(let choice):
                return "Missing \(choice.manifestKey) map style URL."
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case version
        case pmtilesUrl
        case spriteUrl
        case styles
        case publishedAt
    }

    init(version: String, pmtilesUrl: URL, spriteUrl: URL, styles: Styles, publishedAt: String) throws {
        self.version = version
        self.pmtilesUrl = try Self.validHTTPURL(pmtilesUrl, field: CodingKeys.pmtilesUrl.rawValue)
        self.spriteUrl = try Self.validHTTPURL(spriteUrl, field: CodingKeys.spriteUrl.rawValue)
        self.styles = styles
        self.publishedAt = publishedAt

        if let light = styles.light {
            _ = try Self.validHTTPURL(light, field: "styles.light")
        }
        if let dark = styles.dark {
            _ = try Self.validHTTPURL(dark, field: "styles.dark")
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(String.self, forKey: .version)
        let pmtilesUrl = try container.decode(URL.self, forKey: .pmtilesUrl)
        let spriteUrl = try container.decode(URL.self, forKey: .spriteUrl)
        let styles = try container.decode(Styles.self, forKey: .styles)
        let publishedAt = try container.decode(String.self, forKey: .publishedAt)
        try self.init(version: version, pmtilesUrl: pmtilesUrl, spriteUrl: spriteUrl, styles: styles, publishedAt: publishedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(pmtilesUrl, forKey: .pmtilesUrl)
        try container.encode(spriteUrl, forKey: .spriteUrl)
        try container.encode(styles, forKey: .styles)
        try container.encode(publishedAt, forKey: .publishedAt)
    }

    func styleURL(for choice: MapStyleChoice) throws -> URL {
        let url: URL?
        switch choice {
        case .light:
            url = styles.light
        case .dark:
            url = styles.dark
        }

        guard let url else { throw Error.missingStyle(choice: choice) }
        return try Self.validHTTPURL(url, field: "styles.\(choice.manifestKey)")
    }

    static func validHTTPURL(_ url: URL, field: String) throws -> URL {
        guard url.isHTTPOrHTTPS else { throw Error.invalidURL(field: field) }
        return url
    }
}

extension URL {
    var isHTTPOrHTTPS: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
}
