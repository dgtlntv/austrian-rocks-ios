import XCTest
@testable import AustrianRocks

final class SafeURLTests: XCTestCase {
    func testAcceptsOnlyHTTPAndHTTPSURLs() {
        XCTAssertEqual(MapSafeURL.httpURL(from: "https://example.com/guide")?.scheme, "https")
        XCTAssertEqual(MapSafeURL.httpURL(from: "http://example.com/parking")?.scheme, "http")
        XCTAssertNil(MapSafeURL.httpURL(from: "javascript:alert(1)"))
        XCTAssertNil(MapSafeURL.httpURL(from: "file:///tmp/guide"))
        XCTAssertNil(MapSafeURL.httpURL(from: "not a url"))
        XCTAssertNil(MapSafeURL.httpURL(from: nil))
    }
}
