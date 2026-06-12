import XCTest
@testable import AustrianRocks

final class MapSelectionControllerTests: XCTestCase {

    // MARK: - Zoom-safe expression scaling

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

    // MARK: - Animation constants

    func testCircleGrowIsSoftenedAndClearTargetsBaseScale() {
        let controller = MapSelectionController(styling: FakeStyling(), driver: FakeDriver())

        // Intentional deviations from Rails (recorded in the 0005 cross-repo
        // list): circle grow 1.2 instead of 1.4; clear returns to base 1.0
        // instead of 0.72. Icon grow and durations stay on the Rails values.
        XCTAssertEqual(controller.circleGrowScale, 1.2)
        XCTAssertEqual(controller.iconGrowScale, 1.25)
        XCTAssertEqual(controller.clearScale, 1.0)
        XCTAssertEqual(controller.growDuration, 0.52, accuracy: 0.0001)
        XCTAssertEqual(controller.clearDuration, 0.22, accuracy: 0.0001)
    }

    func testCircleSelectionEndsAtSoftenedGrowScale() throws {
        let styling = FakeStyling()
        styling.existingLayers = ["problems-selected"]
        styling.growExpressions["problems-selected"] = NSExpression(forConstantValue: 5)
        let driver = FakeDriver()
        let controller = MapSelectionController(styling: styling, driver: driver)

        controller.select(.problem, id: 3)
        driver.advance(to: 0)
        driver.advance(to: controller.growDuration)

        let final = try XCTUnwrap(styling.growExpressions["problems-selected"]?.mgl_jsonExpressionObject as? [Any])
        XCTAssertEqual(final[0] as? String, "*")
        XCTAssertEqual(try XCTUnwrap(final[1] as? NSNumber).doubleValue, 1.2, accuracy: 0.0001)
    }

    // MARK: - Clear handoff

    func testClearAnimatesSymbolBackToExactBaseScaleWithAtomicFilterSwap() throws {
        let styling = FakeStyling()
        styling.existingLayers = ["regions-selected", "regions"]
        let originalGrow = NSExpression(forConstantValue: 1.5)
        styling.growExpressions["regions-selected"] = originalGrow
        let driver = FakeDriver()
        let controller = MapSelectionController(styling: styling, driver: driver)

        controller.select(.region, id: 7, animated: false)
        XCTAssertEqual(styling.predicates["regions-selected"]??.predicateFormat, "regionId == 7")
        XCTAssertEqual(styling.predicates["regions"]??.predicateFormat, "regionId != 7")

        controller.clear()

        // Mid-animation: scale is between grow and base, and the selected/base
        // filters have NOT swapped yet.
        driver.advance(to: 0)
        driver.advance(to: controller.clearDuration / 2)
        let midJSON = try XCTUnwrap(styling.growExpressions["regions-selected"]?.mgl_jsonExpressionObject as? [Any])
        let midScale = try XCTUnwrap(midJSON[1] as? NSNumber).doubleValue
        XCTAssertGreaterThan(midScale, 1.0)
        XCTAssertLessThan(midScale, 1.25)
        XCTAssertEqual(styling.predicates["regions-selected"]??.predicateFormat, "regionId == 7")
        XCTAssertEqual(styling.predicates["regions"]??.predicateFormat, "regionId != 7")

        // Completion: scale is exactly the original base expression again, and
        // the sentinel + base-layer restore happen in the same frame.
        driver.advance(to: controller.clearDuration)
        XCTAssertTrue(styling.growExpressions["regions-selected"] === originalGrow)
        XCTAssertEqual(styling.predicates["regions-selected"]??.predicateFormat, "regionId == -1")
        XCTAssertEqual(styling.predicates["regions"] ?? nil, nil)
        XCTAssertFalse(driver.isRunning)
    }

    func testClearIfKindOnlyClearsMatchingSelection() {
        let styling = FakeStyling()
        styling.existingLayers = ["pois-selected", "pois"]
        let controller = MapSelectionController(styling: styling, driver: FakeDriver())

        controller.select(.poi, id: 4, animated: false)
        controller.clear(ifKind: .problem, animated: false)
        XCTAssertEqual(styling.predicates["pois-selected"]??.predicateFormat, "poiId == 4")

        controller.clear(ifKind: .poi, animated: false)
        XCTAssertEqual(styling.predicates["pois-selected"]??.predicateFormat, "poiId == -1")
    }

    // MARK: - Driver teardown

    func testClearStopsTheAnimationDriver() {
        let styling = FakeStyling()
        styling.existingLayers = ["problems-selected"]
        let driver = FakeDriver()
        let controller = MapSelectionController(styling: styling, driver: driver)

        controller.select(.problem, id: 3)
        XCTAssertTrue(driver.isRunning)

        controller.clear(animated: false)
        XCTAssertFalse(driver.isRunning)
    }

    func testDeinitStopsTheAnimationDriver() {
        let styling = FakeStyling()
        styling.existingLayers = ["problems-selected"]
        let driver = FakeDriver()
        var controller: MapSelectionController? = MapSelectionController(styling: styling, driver: driver)

        controller?.select(.problem, id: 3)
        XCTAssertTrue(driver.isRunning)

        controller = nil
        XCTAssertFalse(driver.isRunning)
    }

    func testDisplayLinkDriverStopInvalidatesLink() {
        let driver = DisplayLinkAnimationDriver()

        driver.start { _ in }
        XCTAssertTrue(driver.isRunning)

        driver.stop()
        XCTAssertFalse(driver.isRunning)
    }
}

// MARK: - Fakes

private final class FakeStyling: MapSelectionStyling {
    var existingLayers: Set<String> = []
    // Double-optional values record an explicit setPredicate(nil, ...).
    var predicates: [String: NSPredicate?] = [:]
    var growExpressions: [String: NSExpression] = [:]
    var iconRotations: [String: NSExpression] = [:]

    func layerExists(_ identifier: String) -> Bool {
        existingLayers.contains(identifier)
    }

    func predicate(forLayer identifier: String) -> NSPredicate? {
        predicates[identifier] ?? nil
    }

    func setPredicate(_ predicate: NSPredicate?, forLayer identifier: String) {
        guard existingLayers.contains(identifier) else { return }
        predicates[identifier] = predicate
    }

    func growExpression(forLayer identifier: String, isCircle: Bool) -> NSExpression? {
        growExpressions[identifier]
    }

    func setGrowExpression(_ expression: NSExpression, forLayer identifier: String, isCircle: Bool) {
        guard existingLayers.contains(identifier) else { return }
        growExpressions[identifier] = expression
    }

    func iconRotation(forLayer identifier: String) -> NSExpression? {
        iconRotations[identifier]
    }

    func setIconRotation(_ expression: NSExpression, forLayer identifier: String) {
        guard existingLayers.contains(identifier) else { return }
        iconRotations[identifier] = expression
    }
}

private final class FakeDriver: SelectionAnimationDriver {
    private var tick: ((CFTimeInterval) -> Void)?

    var isRunning: Bool { tick != nil }

    func start(_ tick: @escaping (CFTimeInterval) -> Void) {
        self.tick = tick
    }

    func stop() {
        tick = nil
    }

    func advance(to time: CFTimeInterval) {
        tick?(time)
    }
}
