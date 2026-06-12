import XCTest
import SQLite
@testable import AustrianRocks

/// Covers the SQLite cover contract from 0005-P6: a nullable
/// `cover_photo_url` column that today's exports do not have yet — the same
/// app build must work before and after the column ships.
final class RegionCoverPhotoTests: XCTestCase {

    func testLoadToleratesAbsentCoverPhotoColumn() throws {
        let db = try makeRegionsDb(coverColumn: nil)

        let region = try XCTUnwrap(Region.load(id: 1, from: db))

        XCTAssertEqual(region.name, "Maltatal")
        XCTAssertNil(region.coverPhotoUrl)
        XCTAssertNil(region.coverPhotoURL)
    }

    func testNullCoverPhotoValueRendersAsNoCover() throws {
        let db = try makeRegionsDb(coverColumn: .null)

        let region = try XCTUnwrap(Region.load(id: 1, from: db))

        XCTAssertNil(region.coverPhotoUrl)
        XCTAssertNil(region.coverPhotoURL)
    }

    func testNonHTTPCoverPhotoURLRendersAsNoCover() throws {
        let db = try makeRegionsDb(coverColumn: .value("ftp://covers.example.com/maltatal.jpg"))

        let region = try XCTUnwrap(Region.load(id: 1, from: db))

        XCTAssertNotNil(region.coverPhotoUrl)
        XCTAssertNil(region.coverPhotoURL)
    }

    func testHostlessCoverPhotoURLRendersAsNoCover() throws {
        let db = try makeRegionsDb(coverColumn: .value("https:///maltatal.jpg"))

        let region = try XCTUnwrap(Region.load(id: 1, from: db))

        XCTAssertNil(region.coverPhotoURL)
    }

    func testValidHTTPSCoverPhotoURLIsExposed() throws {
        let db = try makeRegionsDb(coverColumn: .value("https://covers.example.com/maltatal.jpg"))

        let region = try XCTUnwrap(Region.load(id: 1, from: db))

        XCTAssertEqual(region.coverPhotoURL?.absoluteString, "https://covers.example.com/maltatal.jpg")
    }

    func testCoverPhotoURLValidatorRejectsInvalidValues() {
        XCTAssertNil(Region.coverPhotoURL(from: nil))
        XCTAssertNil(Region.coverPhotoURL(from: ""))
        XCTAssertNil(Region.coverPhotoURL(from: "ftp://example.com/a.jpg"))
        XCTAssertNil(Region.coverPhotoURL(from: "https:foo"))
        XCTAssertEqual(
            Region.coverPhotoURL(from: "https://example.com/a.jpg")?.absoluteString,
            "https://example.com/a.jpg"
        )
    }

    // MARK: - Helpers

    private enum CoverColumn {
        case null
        case value(String)
    }

    private func makeRegionsDb(coverColumn: CoverColumn?) throws -> Connection {
        let db = try Connection(.inMemory)

        let coverDefinition = coverColumn != nil ? ", cover_photo_url TEXT" : ""
        try db.run("""
        CREATE TABLE regions (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            slug TEXT,
            main_cluster_id INTEGER,
            center_lat DOUBLE,
            center_lon DOUBLE,
            south_west_lat DOUBLE,
            south_west_lon DOUBLE,
            north_east_lat DOUBLE,
            north_east_lon DOUBLE,
            tags TEXT,
            published BOOLEAN\(coverDefinition)
        )
        """)

        switch coverColumn {
        case nil:
            try db.run("INSERT INTO regions (id, name, published) VALUES (1, 'Maltatal', 1)")
        case .null:
            try db.run("INSERT INTO regions (id, name, published, cover_photo_url) VALUES (1, 'Maltatal', 1, NULL)")
        case .value(let url):
            try db.run("INSERT INTO regions (id, name, published, cover_photo_url) VALUES (1, 'Maltatal', 1, ?)", url)
        }

        return db
    }
}
