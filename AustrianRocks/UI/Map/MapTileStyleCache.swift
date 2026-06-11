//
//  MapTileStyleCache.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import Foundation

struct MapTileStyleCache {
    struct CachedStyle: Equatable {
        let manifest: MapTileManifest
        let choice: MapStyleChoice
        let styleURL: URL
    }

    private struct Record: Codable {
        let manifest: MapTileManifest
        let choice: MapStyleChoice
        let styleURL: URL
    }

    private let userDefaults: UserDefaults
    private let manifestKey: String
    private let styleKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults = .standard,
        manifestKey: String = BrandConfig.MapTiles.lastKnownManifestCacheKey,
        styleKey: String = BrandConfig.MapTiles.lastKnownStyleCacheKey,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.manifestKey = manifestKey
        self.styleKey = styleKey
        self.encoder = encoder
        self.decoder = decoder
    }

    func recordSuccess(manifest: MapTileManifest, choice: MapStyleChoice, styleURL: URL) throws {
        let safeStyleURL = try MapTileManifest.validHTTPURL(styleURL, field: "cachedStyle")
        let manifestData = try encoder.encode(manifest)
        let record = Record(manifest: manifest, choice: choice, styleURL: safeStyleURL)
        userDefaults.set(manifestData, forKey: manifestKey)
        userDefaults.set(try encoder.encode(record), forKey: styleKey)
    }

    func lastKnownStyle(for choice: MapStyleChoice) -> CachedStyle? {
        guard let data = userDefaults.data(forKey: styleKey),
              let record = try? decoder.decode(Record.self, from: data),
              record.choice == choice,
              record.styleURL.isHTTPOrHTTPS else {
            return nil
        }

        return CachedStyle(manifest: record.manifest, choice: record.choice, styleURL: record.styleURL)
    }

    func clear() {
        userDefaults.removeObject(forKey: manifestKey)
        userDefaults.removeObject(forKey: styleKey)
    }
}
