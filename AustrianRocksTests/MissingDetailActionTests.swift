import XCTest
@testable import AustrianRocks

final class MissingDetailActionTests: XCTestCase {
    func testMissingSQLiteDetailDisablesSecondaryActionWithoutCrashing() {
        let model = MapFeatureCardModel.make(
            kind: .area,
            properties: ["areaId": 42, "name": "Zillertal"],
            detailAvailabilityResolver: { _, _ in false }
        )

        XCTAssertNotNil(model)
        XCTAssertEqual(model?.detailAvailability.canOpenDetail, false)
    }

    func testPresentSQLiteDetailEnablesSecondaryAction() {
        let model = MapFeatureCardModel.make(
            kind: .cluster,
            properties: ["clusterId": 7, "name": "Wachau"],
            detailAvailabilityResolver: { kind, id in kind == .cluster && id == 7 }
        )

        XCTAssertEqual(model?.detailAvailability.canOpenDetail, true)
    }
}
