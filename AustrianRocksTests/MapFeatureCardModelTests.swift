import XCTest
@testable import AustrianRocks

final class MapFeatureCardModelTests: XCTestCase {
    func testBuildsLocalizedEntityCardFromTileProperties() throws {
        let model = try XCTUnwrap(MapFeatureCardModel.make(
            kind: .region,
            properties: [
                "regionId": 5,
                "name": "Ötztal",
                "nameEn": "Oetztal",
                "problemCount": 123,
                "gradeMin": "4a",
                "gradeMax": "8a",
                "warning": "Achtung",
                "warningEn": "Careful",
                "coverPhotoUrl": "https://images.austrian.rocks/cover.jpg",
                "guidebookUrl": "https://austrian.rocks/guide",
                "guidebookTitle": "Best of Tirol",
                "guidebookAuthor": "Austrian Rocks",
                "parkingGoogleUrl": "https://maps.google.com/?q=parking",
                "parkingName": "Main parking",
                "southWestLat": 46.8,
                "southWestLon": 10.8,
                "northEastLat": 47.2,
                "northEastLon": 11.2,
                "mainClusterSouthWestLat": 46.9,
                "mainClusterSouthWestLon": 10.9,
                "mainClusterNorthEastLat": 47.0,
                "mainClusterNorthEastLon": 11.0
            ],
            localeIdentifier: "en",
            detailAvailabilityResolver: { _, _ in true }
        ))

        XCTAssertEqual(model.title, "Oetztal")
        XCTAssertEqual(model.problemCount, 123)
        XCTAssertEqual(model.gradeMin, "4a")
        XCTAssertEqual(model.gradeMax, "8a")
        XCTAssertEqual(model.warning, "Careful")
        XCTAssertEqual(model.coverPhotoURL?.scheme, "https")
        XCTAssertEqual(model.guidebook?.title, "Best of Tirol")
        XCTAssertEqual(model.guidebook?.author, "Austrian Rocks")
        XCTAssertEqual(model.parking?.name, "Main parking")
        XCTAssertEqual(model.bounds?.southWest.latitude, 46.9)
        XCTAssertEqual(model.bounds?.northEast.longitude, 11.0)
        XCTAssertTrue(model.detailAvailability.canOpenDetail)
    }

    func testFallsBackToBaseNameAndOmitsAbsentOptionalRows() throws {
        let model = try XCTUnwrap(MapFeatureCardModel.make(
            kind: .area,
            properties: ["areaId": "9", "name": "Magic Wood", "guidebookUrl": "https://example.com"],
            localeIdentifier: "en",
            detailAvailabilityResolver: { _, _ in false }
        ))

        XCTAssertEqual(model.title, "Magic Wood")
        XCTAssertNil(model.warning)
        XCTAssertNil(model.guidebook)
        XCTAssertNil(model.parking)
        XCTAssertNil(model.coverPhotoURL)
        XCTAssertFalse(model.detailAvailability.canOpenDetail)
    }

    func testParsesAndPadsGradeHistogramInOrder() throws {
        let model = try XCTUnwrap(MapFeatureCardModel.make(
            kind: .cluster,
            properties: [
                "clusterId": 3,
                "name": "Silvretta",
                "gradeHistogramJson": "{\"6a\":2,\"6c\":5}"
            ],
            detailAvailabilityResolver: { _, _ in false }
        ))

        XCTAssertEqual(model.gradeHistogram.map(\.grade), ["6a", "6b", "6c", "7a", "7b"])
        XCTAssertEqual(model.gradeHistogram.map(\.count), [2, 0, 5, 0, 0])
    }

    func testRejectsInvalidHistogramAndBounds() throws {
        let model = try XCTUnwrap(MapFeatureCardModel.make(
            kind: .area,
            properties: [
                "areaId": 1,
                "name": "Area",
                "gradeHistogramJson": "{\"bad\":1}",
                "southWestLat": 47,
                "southWestLon": 16,
                "northEastLat": 46,
                "northEastLon": 15
            ],
            detailAvailabilityResolver: { _, _ in false }
        ))

        XCTAssertTrue(model.gradeHistogram.isEmpty)
        XCTAssertNil(model.bounds)
    }

    func testBuildsPOICardWithSafeDirectionsOnly() throws {
        let model = try XCTUnwrap(MapFeatureCardModel.make(
            kind: .poi,
            properties: [
                "poiId": 11,
                "name": "Parkplatz",
                "poiType": "parking",
                "googleUrl": "https://maps.google.com/?q=parkplatz"
            ]
        ))

        XCTAssertEqual(model.poiType, .parking)
        XCTAssertEqual(model.googleURL?.scheme, "https")

        let unsafe = try XCTUnwrap(MapFeatureCardModel.make(
            kind: .poi,
            properties: ["poiId": 12, "name": "Bahnhof", "poiType": "train_station", "googleUrl": "javascript:alert(1)"]
        ))
        XCTAssertEqual(unsafe.poiType, .trainStation)
        XCTAssertNil(unsafe.googleURL)
    }
}
