import XCTest
@testable import CodableSQLite

final class CodableSQLiteTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CodableSQLite().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
