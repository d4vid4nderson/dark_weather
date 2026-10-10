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

    func testAgo() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(Format.ago(now.addingTimeInterval(-30), now: now), "just now")
        XCTAssertEqual(Format.ago(now.addingTimeInterval(-5 * 60), now: now), "5m ago")
        XCTAssertEqual(Format.ago(now.addingTimeInterval(-2 * 3600), now: now), "2h ago")
        XCTAssertEqual(Format.ago(now.addingTimeInterval(-30 * 3600), now: now), "yesterday")
        XCTAssertEqual(Format.ago(now.addingTimeInterval(-3 * 86_400), now: now), "3d ago")
        XCTAssertEqual(Format.ago(now.addingTimeInterval(60), now: now), "just now")
    }

    func testPadding() {
        XCTAssertEqual("7°".leftPadded(to: 4), "  7°")
        XCTAssertEqual("rain".rightPadded(to: 6), "rain  ")
        XCTAssertEqual("toolong".rightPadded(to: 3), "toolong")
    }
}
