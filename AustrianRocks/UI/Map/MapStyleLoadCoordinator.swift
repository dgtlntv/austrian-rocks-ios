//
//  MapStyleLoadCoordinator.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import Foundation

@MainActor
final class MapStyleLoadCoordinator {
    typealias FetchManifest = (URL) async throws -> MapTileManifest
    typealias RecordSuccess = (MapTileManifest, MapStyleChoice, URL) throws -> Void
    typealias LastKnownStyle = (MapStyleChoice) -> MapTileStyleCache.CachedStyle?

    enum LoadAction: Equatable {
        case install(URL, forceReload: Bool)
        case available
        case unavailable(String)
        case none
    }

    private enum AttemptSource {
        case fresh(manifest: MapTileManifest, choice: MapStyleChoice)
        case cached
    }

    private struct StyleAttempt {
        let url: URL
        let source: AttemptSource
        let fallback: MapTileStyleCache.CachedStyle?
    }

    private let manifestURL: URL
    private let fetchManifest: FetchManifest
    private let recordSuccess: RecordSuccess
    private let lastKnownStyle: LastKnownStyle
    private var pendingAttempt: StyleAttempt?

    init(
        manifestURL: URL = BrandConfig.MapTiles.manifestURL,
        fetchManifest: @escaping FetchManifest,
        recordSuccess: @escaping RecordSuccess,
        lastKnownStyle: @escaping LastKnownStyle
    ) {
        self.manifestURL = manifestURL
        self.fetchManifest = fetchManifest
        self.recordSuccess = recordSuccess
        self.lastKnownStyle = lastKnownStyle
    }

    func loadStyle(for choice: MapStyleChoice, unavailableMessage: String) async -> LoadAction {
        let cachedFallback = lastKnownStyle(choice)

        do {
            let manifest = try await fetchManifest(manifestURL)
            let styleURL = try manifest.styleURL(for: choice)
            pendingAttempt = StyleAttempt(
                url: styleURL,
                source: .fresh(manifest: manifest, choice: choice),
                fallback: cachedFallback
            )
            return .install(styleURL, forceReload: true)
        } catch {
            if let cachedFallback {
                pendingAttempt = StyleAttempt(url: cachedFallback.styleURL, source: .cached, fallback: nil)
                return .install(cachedFallback.styleURL, forceReload: true)
            }

            pendingAttempt = nil
            return .unavailable(unavailableMessage)
        }
    }

    func styleDidLoad(url: URL?) -> LoadAction {
        guard let attempt = matchingPendingAttempt(for: url) else {
            return pendingAttempt == nil ? .available : .none
        }

        if case .fresh(let manifest, let choice) = attempt.source {
            try? recordSuccess(manifest, choice, attempt.url)
        }

        pendingAttempt = nil
        return .available
    }

    func styleDidFail(url: URL?, message: String) -> LoadAction {
        guard let attempt = matchingPendingAttempt(for: url) else {
            return pendingAttempt == nil ? .unavailable(message) : .none
        }

        switch attempt.source {
        case .fresh:
            if let fallback = attempt.fallback {
                pendingAttempt = StyleAttempt(url: fallback.styleURL, source: .cached, fallback: nil)
                return .install(fallback.styleURL, forceReload: true)
            }

            pendingAttempt = nil
            return .unavailable(message)
        case .cached:
            pendingAttempt = nil
            return .unavailable(message)
        }
    }

    private func matchingPendingAttempt(for url: URL?) -> StyleAttempt? {
        guard let pendingAttempt else { return nil }
        guard let url else { return pendingAttempt }
        return pendingAttempt.url == url ? pendingAttempt : nil
    }
}
