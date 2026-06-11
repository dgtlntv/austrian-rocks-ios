import XCTest
@testable import AustrianRocks

final class MapTileManifestTests: XCTestCase {
    func testDecodesManifestAndSelectsStyles() throws {
        let data = Data("""
        {
          "version":"2026-06-10T22-12-52Z",
          "pmtilesUrl":"https://tiles.austrian.rocks/map_tiles/e2e/austrian-rocks.pmtiles",
          "spriteUrl":"https://tiles.austrian.rocks/map_styles/sprite",
          "styles":{
            "light":"https://tiles.austrian.rocks/map_styles/light.json",
            "dark":"https://tiles.austrian.rocks/map_styles/dark.json"
          },
          "publishedAt":"2026-06-10T22:12:55Z"
        }
        """.utf8)

        let manifest = try JSONDecoder().decode(MapTileManifest.self, from: data)

        XCTAssertEqual(manifest.version, "2026-06-10T22-12-52Z")
        XCTAssertEqual(try manifest.styleURL(for: .light).absoluteString, "https://tiles.austrian.rocks/map_styles/light.json")
        XCTAssertEqual(try manifest.styleURL(for: .dark).absoluteString, "https://tiles.austrian.rocks/map_styles/dark.json")
    }

    func testRejectsNonHTTPURLs() throws {
        let data = Data("""
        {
          "version":"bad",
          "pmtilesUrl":"pmtiles://tiles.austrian.rocks/archive.pmtiles",
          "spriteUrl":"https://tiles.austrian.rocks/map_styles/sprite",
          "styles":{"light":"https://tiles.austrian.rocks/light.json","dark":"https://tiles.austrian.rocks/dark.json"},
          "publishedAt":"now"
        }
        """.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(MapTileManifest.self, from: data))
    }

    func testRejectsHostlessHTTPURLs() throws {
        let data = Data("""
        {
          "version":"bad",
          "pmtilesUrl":"https:archive.pmtiles",
          "spriteUrl":"https://tiles.austrian.rocks/map_styles/sprite",
          "styles":{"light":"https:///light.json","dark":"https://tiles.austrian.rocks/dark.json"},
          "publishedAt":"now"
        }
        """.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(MapTileManifest.self, from: data))
    }

    func testMissingStyleThrowsTypedError() throws {
        let manifest = try MapTileManifest(
            version: "v1",
            pmtilesUrl: URL(string: "https://tiles.austrian.rocks/archive.pmtiles")!,
            spriteUrl: URL(string: "https://tiles.austrian.rocks/sprite")!,
            styles: .init(light: URL(string: "https://tiles.austrian.rocks/light.json")!, dark: nil),
            publishedAt: "now"
        )

        XCTAssertThrowsError(try manifest.styleURL(for: .dark)) { error in
            XCTAssertEqual(error as? MapTileManifest.Error, .missingStyle(choice: .dark))
        }
    }

    func testStyleChoiceFollowsInterfaceStyle() {
        XCTAssertEqual(MapStyleChoice(userInterfaceStyle: .dark), .dark)
        XCTAssertEqual(MapStyleChoice(userInterfaceStyle: .light), .light)
        XCTAssertEqual(MapStyleChoice(userInterfaceStyle: .unspecified), .light)
        XCTAssertEqual(MapStyleChoice.dark.manifestKey, "dark")
    }

    func testClientUsesNoStoreRequestAndValidatesStatus() async throws {
        let manifestData = Data("""
        {"version":"v1","pmtilesUrl":"https://tiles.austrian.rocks/a.pmtiles","spriteUrl":"https://tiles.austrian.rocks/sprite","styles":{"light":"https://tiles.austrian.rocks/light.json","dark":"https://tiles.austrian.rocks/dark.json"},"publishedAt":"now"}
        """.utf8)
        var capturedRequest: URLRequest?
        let client = MapTileManifestClient { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (manifestData, response)
        }

        let manifest = try await client.fetchManifest(from: URL(string: "https://tiles.austrian.rocks/map_tiles/current.json")!)

        XCTAssertEqual(manifest.version, "v1")
        XCTAssertEqual(capturedRequest?.cachePolicy, .reloadIgnoringLocalAndRemoteCacheData)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Cache-Control"), "no-store")
    }
}
