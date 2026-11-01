import XCTest
@testable import DarkWeather

final class WeatherConditionTests: XCTestCase {
    func testWMOCodeMapping() {
        XCTAssertEqual(WeatherCondition(wmoCode: 0), .clear)
        XCTAssertEqual(WeatherCondition(wmoCode: 3), .cloudy)
        XCTAssertEqual(WeatherCondition(wmoCode: 45), .fog)
        XCTAssertEqual(WeatherCondition(wmoCode: 53), .drizzle)
        XCTAssertEqual(WeatherCondition(wmoCode: 66), .freezingRain)
        XCTAssertEqual(WeatherCondition(wmoCode: 81), .rain)
        XCTAssertEqual(WeatherCondition(wmoCode: 86), .snow)
        XCTAssertEqual(WeatherCondition(wmoCode: 99), .thunderstorm)
        XCTAssertEqual(WeatherCondition(wmoCode: 1234), .unknown)
    }

    func testAsciiArtIsFiveLinesOfThirteenColumns() {
        for condition in WeatherCondition.allCases {
            for isDaylight in [true, false] {
                let art = condition.asciiArt(isDaylight: isDaylight)
                XCTAssertEqual(art.count, 5, "\(condition)")
                XCTAssertTrue(art.allSatisfy { $0.count == 13 }, "\(condition)")
            }
        }
    }

    func testClearSkyShowsMoonAfterDark() {
        XCTAssertNotEqual(WeatherCondition.clear.asciiArt(isDaylight: true), WeatherCondition.clear.asciiArt(isDaylight: false))
    }

    func testShortLabelsFitTableColumn() {
        XCTAssertTrue(WeatherCondition.allCases.allSatisfy { $0.shortLabel.count <= 6 })
    }
}
