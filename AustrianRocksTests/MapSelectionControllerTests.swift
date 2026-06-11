import XCTest
@testable import AustrianRocks

final class MapSelectionControllerTests: XCTestCase {
    func testScalesInterpolateZoomOutputsWithoutWrappingZoomExpression() throws {
        let expression: [Any] = ["interpolate", ["linear"], ["zoom"], 15, 5, 18, 7, 22, 13]

        let scaled = try XCTUnwrap(MapSelectionController.zoomSafeScaledJSONObject(expression, scale: 1.4) as? [Any])

        XCTAssertEqual(scaled[0] as? String, "interpolate")
        XCTAssertEqual(scaled[2] as? [String], ["zoom"])
        XCTAssertEqual(try XCTUnwrap(scaled[4] as? NSNumber).doubleValue, 7.0, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(scaled[6] as? NSNumber).doubleValue, 9.8, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(scaled[8] as? NSNumber).doubleValue, 18.2, accuracy: 0.0001)
    }

    func testScalesStepZoomOutputsWithoutWrappingZoomExpression() throws {
        let expression: [Any] = ["step", ["zoom"], 1, 10, 2, 15, 3]

        let scaled = try XCTUnwrap(MapSelectionController.zoomSafeScaledJSONObject(expression, scale: 1.25) as? [Any])

        XCTAssertEqual(scaled[0] as? String, "step")
        XCTAssertEqual(scaled[1] as? [String], ["zoom"])
        XCTAssertEqual(try XCTUnwrap(scaled[2] as? NSNumber).doubleValue, 1.25, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(scaled[4] as? NSNumber).doubleValue, 2.5, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(scaled[6] as? NSNumber).doubleValue, 3.75, accuracy: 0.0001)
    }

    func testNonZoomExpressionsUseDefaultScalingPath() {
        let expression: [Any] = ["get", "iconSize"]

        XCTAssertNil(MapSelectionController.zoomSafeScaledJSONObject(expression, scale: 1.25))
    }
}
