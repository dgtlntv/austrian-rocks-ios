import XCTest
@testable import AustrianRocks

@MainActor
final class MapStyleLoadCoordinatorTests: XCTestCase {
    func testFreshStyleIsCachedOnlyAfterMapLibreReportsLoaded() async throws {
        let manifest = try makeManifest(light: "https://tiles.austrian.rocks/fresh-light.json")
        var recorded: [(MapTileManifest, MapStyleChoice, URL)] = []
        let coordinator = makeCoordinator(
            fetchManifest: { _ in manifest },
            recordSuccess: { manifest, choice, styleURL in recorded.append((manifest, choice, styleURL)) },
            lastKnownStyle: { _ in nil }
        )

        let action = await coordinator.loadStyle(for: .light, unavailableMessage: "unavailable")

        XCTAssertEqual(action, .install(URL(string: "https://tiles.austrian.rocks/fresh-light.json")!, forceReload: true))
        XCTAssertTrue(recorded.isEmpty)
        XCTAssertEqual(coordinator.styleDidLoad(url: URL(string: "https://tiles.austrian.rocks/fresh-light.json")!), .available)
        XCTAssertEqual(recorded.count, 1)
        XCTAssertEqual(recorded.first?.1, .light)
        XCTAssertEqual(recorded.first?.2, URL(string: "https://tiles.austrian.rocks/fresh-light.json")!)
    }

    func testManifestFailureInstallsCachedStyleWhenAvailable() async throws {
        let cached = try cachedStyle(choice: .dark, url: "https://tiles.austrian.rocks/cached-dark.json")
        var didRecordFreshSuccess = false
        let coordinator = makeCoordinator(
            fetchManifest: { _ in throw URLError(.notConnectedToInternet) },
            recordSuccess: { _, _, _ in didRecordFreshSuccess = true },
            lastKnownStyle: { choice in choice == .dark ? cached : nil }
        )

        let action = await coordinator.loadStyle(for: .dark, unavailableMessage: "unavailable")

        XCTAssertEqual(action, .install(URL(string: "https://tiles.austrian.rocks/cached-dark.json")!, forceReload: true))
        XCTAssertEqual(coordinator.styleDidLoad(url: URL(string: "https://tiles.austrian.rocks/cached-dark.json")!), .available)
        XCTAssertFalse(didRecordFreshSuccess)
    }

    func testFreshStyleFailureFallsBackToPriorCachedStyleWithoutPoisoningCache() async throws {
        let manifest = try makeManifest(light: "https://tiles.austrian.rocks/broken-light.json")
        let cached = try cachedStyle(choice: .light, url: "https://tiles.austrian.rocks/working-light.json")
        var recordedURLs: [URL] = []
        let coordinator = makeCoordinator(
            fetchManifest: { _ in manifest },
            recordSuccess: { _, _, styleURL in recordedURLs.append(styleURL) },
            lastKnownStyle: { choice in choice == .light ? cached : nil }
        )

        let action = await coordinator.loadStyle(for: .light, unavailableMessage: "unavailable")

        XCTAssertEqual(action, .install(URL(string: "https://tiles.austrian.rocks/broken-light.json")!, forceReload: true))
        XCTAssertEqual(
            coordinator.styleDidFail(url: URL(string: "https://tiles.austrian.rocks/broken-light.json")!, message: "style failed"),
            .install(URL(string: "https://tiles.austrian.rocks/working-light.json")!, forceReload: true)
        )
        XCTAssertTrue(recordedURLs.isEmpty)
        XCTAssertEqual(coordinator.styleDidLoad(url: URL(string: "https://tiles.austrian.rocks/working-light.json")!), .available)
        XCTAssertTrue(recordedURLs.isEmpty)
    }

    func testUnavailableWhenNeitherFreshManifestNorCachedStyleCanInstall() async {
        let coordinator = makeCoordinator(
            fetchManifest: { _ in throw URLError(.cannotFindHost) },
            recordSuccess: { _, _, _ in XCTFail("No style should be recorded") },
            lastKnownStyle: { _ in nil }
        )

        let action = await coordinator.loadStyle(for: .light, unavailableMessage: "unavailable")

        XCTAssertEqual(action, .unavailable("unavailable"))
    }

    func testRetryReinstallsSameURLRatherThanTreatingItAsAlreadyAvailable() async throws {
        let manifest = try makeManifest(light: "https://tiles.austrian.rocks/retry-light.json")
        let coordinator = makeCoordinator(
            fetchManifest: { _ in manifest },
            recordSuccess: { _, _, _ in },
            lastKnownStyle: { _ in nil }
        )
        let expected = MapStyleLoadCoordinator.LoadAction.install(URL(string: "https://tiles.austrian.rocks/retry-light.json")!, forceReload: true)

        let firstRetryAction = await coordinator.loadStyle(for: .light, unavailableMessage: "unavailable")
        XCTAssertEqual(firstRetryAction, expected)
        XCTAssertEqual(coordinator.styleDidFail(url: URL(string: "https://tiles.austrian.rocks/retry-light.json")!, message: "style failed"), .unavailable("style failed"))
        let secondRetryAction = await coordinator.loadStyle(for: .light, unavailableMessage: "unavailable")
        XCTAssertEqual(secondRetryAction, expected)
    }

    func testTraitChangeLoadsTheStyleForTheNewChoice() async throws {
        let manifest = try makeManifest(
            light: "https://tiles.austrian.rocks/light.json",
            dark: "https://tiles.austrian.rocks/dark.json"
        )
        let coordinator = makeCoordinator(
            fetchManifest: { _ in manifest },
            recordSuccess: { _, _, _ in },
            lastKnownStyle: { _ in nil }
        )

        let lightAction = await coordinator.loadStyle(for: .light, unavailableMessage: "unavailable")
        XCTAssertEqual(lightAction, .install(URL(string: "https://tiles.austrian.rocks/light.json")!, forceReload: true))
        XCTAssertEqual(coordinator.styleDidLoad(url: URL(string: "https://tiles.austrian.rocks/light.json")!), .available)
        let darkAction = await coordinator.loadStyle(for: .dark, unavailableMessage: "unavailable")
        XCTAssertEqual(darkAction, .install(URL(string: "https://tiles.austrian.rocks/dark.json")!, forceReload: true))
    }

    private func makeCoordinator(
        fetchManifest: @escaping MapStyleLoadCoordinator.FetchManifest,
        recordSuccess: @escaping MapStyleLoadCoordinator.RecordSuccess,
        lastKnownStyle: @escaping MapStyleLoadCoordinator.LastKnownStyle
    ) -> MapStyleLoadCoordinator {
        MapStyleLoadCoordinator(
            manifestURL: URL(string: "https://tiles.austrian.rocks/map_tiles/current.json")!,
            fetchManifest: fetchManifest,
            recordSuccess: recordSuccess,
            lastKnownStyle: lastKnownStyle
        )
    }

    private func cachedStyle(choice: MapStyleChoice, url: String) throws -> MapTileStyleCache.CachedStyle {
        try MapTileStyleCache.CachedStyle(
            manifest: makeManifest(light: "https://tiles.austrian.rocks/light.json", dark: "https://tiles.austrian.rocks/dark.json"),
            choice: choice,
            styleURL: URL(string: url)!
        )
    }

    private func makeManifest(
        light: String = "https://tiles.austrian.rocks/light.json",
        dark: String = "https://tiles.austrian.rocks/dark.json"
    ) throws -> MapTileManifest {
        try MapTileManifest(
            version: "v1",
            pmtilesUrl: URL(string: "https://tiles.austrian.rocks/archive.pmtiles")!,
            spriteUrl: URL(string: "https://tiles.austrian.rocks/sprite")!,
            styles: .init(light: URL(string: light)!, dark: URL(string: dark)!),
            publishedAt: "now"
        )
    }
}
