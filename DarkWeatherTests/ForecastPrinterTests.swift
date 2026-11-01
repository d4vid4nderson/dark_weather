import XCTest
@testable import DarkWeather

final class ForecastPrinterTests: XCTestCase {
    private let report = PreviewData.report()

    private func text(_ line: TerminalLine) -> String {
        line.segments.map(\.text).joined()
    }

    func testHeadersAreFullWidth() {
        let header = ForecastPrinter.header("hourly")
        XCTAssertEqual(text(header).count, ForecastPrinter.width)
        XCTAssertTrue(text(header).hasPrefix("── hourly "))
    }

    func testPrintsEverySection() {
        let lines = ForecastPrinter.lines(for: report, placeName: "Austin, TX").map(text)

        XCTAssertEqual(lines.first, "# austin, tx")
        let hourly = try! XCTUnwrap(lines.firstIndex { $0.hasPrefix("── hourly") })
        let daily = try! XCTUnwrap(lines.firstIndex { $0.hasPrefix("── 10-day") })
        let details = try! XCTUnwrap(lines.firstIndex { $0.hasPrefix("── details") })

        // 12 hourly rows then a blank line before the next header.
        XCTAssertEqual(daily - hourly - 2, 12)
        XCTAssertEqual(details - daily - 2, report.daily.count)
        XCTAssertTrue(lines[hourly + 1].hasPrefix("now"))
        XCTAssertTrue(lines[daily + 1].hasPrefix("today"))
        XCTAssertTrue(lines.last?.hasPrefix("wind") == true)
    }

    func testTableRowsFitTheWidth() {
        let lines = ForecastPrinter.lines(for: report, placeName: "Austin, TX").map(text)
        let tooWide = lines.filter { $0.count > ForecastPrinter.width }
        XCTAssertEqual(tooWide, [])
    }

    func testSummaryNamesPlaceAndCondition() {
        let summary = ForecastPrinter.summary(for: report, placeName: "Austin, TX")
        XCTAssertTrue(summary.hasPrefix("Austin, TX: "))
        XCTAssertTrue(summary.contains("Partly Cloudy"))
    }
}
