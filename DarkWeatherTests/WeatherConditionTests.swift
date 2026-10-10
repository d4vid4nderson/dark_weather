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

    func testClearSkyUsesNightSymbolAfterDark() {
        XCTAssertEqual(WeatherCondition.clear.symbolName(isDaylight: true), "sun.max.fill")
        XCTAssertEqual(WeatherCondition.clear.symbolName(isDaylight: false), "moon.stars.fill")
    }
}
