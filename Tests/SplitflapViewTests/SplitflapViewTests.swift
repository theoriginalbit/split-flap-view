@testable import SplitflapView
import XCTest

final class SplitflapViewTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SplitflapView(tokens: ["A"]).tokens, ["A"])
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
