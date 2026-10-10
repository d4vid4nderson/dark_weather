import XCTest
@testable import DarkWeather

final class TerminalLineTests: XCTestCase {
    private let line = TerminalLine([.init(text: "ab", style: .dim), .init(text: "cde", style: .warm)])

    func testLengthCountsAllSegmentsAndBlankLinesCostOne() {
        XCTAssertEqual(line.length, 5)
        XCTAssertEqual(TerminalLine.blank.length, 1)
    }

    func testPrefixKeepsStylesAcrossSegments() {
        XCTAssertEqual(line.prefix(3), TerminalLine([.init(text: "ab", style: .dim), .init(text: "c", style: .warm)]))
        XCTAssertEqual(line.prefix(1), TerminalLine([.init(text: "a", style: .dim)]))
        XCTAssertEqual(line.prefix(99), line)
        XCTAssertEqual(line.prefix(0), TerminalLine([]))
    }
}
