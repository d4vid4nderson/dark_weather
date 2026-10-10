import XCTest
@testable import DarkWeather

final class FormatTests: XCTestCase {
    func testRangeBarFillsFullRange() {
        XCTAssertEqual(Format.rangeBar(low: 10, high: 20, in: 10...20, width: 5), "█████")
    }

    func testRangeBarMarksSubrange() {
        XCTAssertEqual(Format.rangeBar(low: 10, high: 15, in: 10...20, width: 5), "███░░")
        XCTAssertEqual(Format.rangeBar(low: 15, high: 20, in: 10...20, width: 5), "░░███")
    }

    func testRangeBarHandlesEmptySpan() {
        XCTAssertEqual(Format.rangeBar(low: 10, high: 10, in: 10...10, width: 3), "███")
    }

    func testPadding() {
        XCTAssertEqual("7°".leftPadded(to: 4), "  7°")
        XCTAssertEqual("rain".rightPadded(to: 6), "rain  ")
        XCTAssertEqual("toolong".rightPadded(to: 3), "toolong")
    }
}
