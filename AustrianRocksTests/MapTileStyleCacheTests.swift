import XCTest
@testable import AustrianRocks

final class MapTileStyleCacheTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "MapTileStyleCacheTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testRecordsAndReturnsLastKnownStyleForChoice() throws {
        let manifest = try manifest(version: "v1")
        let cache = MapTileStyleCache(userDefaults: defaults)
        let styleURL = URL(string: "https://tiles.austrian.rocks/dark.json")!

        try cache.recordSuccess(manifest: manifest, choice: .dark, styleURL: styleURL)

        let cached = cache.lastKnownStyle(for: .dark)
        XCTAssertEqual(cached?.manifest.version, "v1")
        XCTAssertEqual(cached?.choice, .dark)
        XCTAssertEqual(cached?.styleURL, styleURL)
        XCTAssertNil(cache.lastKnownStyle(for: .light))
    }

    func testRejectsUnsafeCachedStyleURL() throws {
        let manifest = try manifest(version: "v1")
        let cache = MapTileStyleCache(userDefaults: defaults)

        XCTAssertThrowsError(try cache.recordSuccess(manifest: manifest, choice: .light, styleURL: URL(string: "file:///tmp/light.json")!))
    }

    func testClearRemovesCachedStyle() throws {
        let cache = MapTileStyleCache(userDefaults: defaults)
        try cache.recordSuccess(manifest: try manifest(version: "v1"), choice: .light, styleURL: URL(string: "https://tiles.austrian.rocks/light.json")!)

        cache.clear()

        XCTAssertNil(cache.lastKnownStyle(for: .light))
    }

    private func manifest(version: String) throws -> MapTileManifest {
        try MapTileManifest(
            version: version,
            pmtilesUrl: URL(string: "https://tiles.austrian.rocks/a.pmtiles")!,
            spriteUrl: URL(string: "https://tiles.austrian.rocks/sprite")!,
            styles: .init(
                light: URL(string: "https://tiles.austrian.rocks/light.json")!,
                dark: URL(string: "https://tiles.austrian.rocks/dark.json")!
            ),
            publishedAt: "now"
        )
    }
}
