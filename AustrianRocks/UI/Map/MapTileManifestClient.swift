//
//  MapTileManifestClient.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import Foundation

struct MapTileManifestClient {
    typealias DataLoader = (URLRequest) async throws -> (Data, URLResponse)

    private let dataLoader: DataLoader
    private let decoder: JSONDecoder

    init(dataLoader: @escaping DataLoader = { request in
        try await URLSession.shared.data(for: request)
    }, decoder: JSONDecoder = JSONDecoder()) {
        self.dataLoader = dataLoader
        self.decoder = decoder
    }

    func fetchManifest(from url: URL) async throws -> MapTileManifest {
        _ = try MapTileManifest.validHTTPURL(url, field: "manifest")

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        let (data, response) = try await dataLoader(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }

        return try decoder.decode(MapTileManifest.self, from: data)
    }
}
