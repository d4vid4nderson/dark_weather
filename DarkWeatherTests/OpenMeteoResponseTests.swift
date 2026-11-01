import XCTest
@testable import DarkWeather

final class OpenMeteoResponseTests: XCTestCase {
    // Trimmed real-shape payload (timeformat=unixtime).
    private let json = """
    {
      "current": {
        "time": 1760104800, "temperature_2m": 21.4, "apparent_temperature": 20.9,
        "relative_humidity_2m": 54, "wind_speed_10m": 11.2, "weather_code": 2, "is_day": 1
      },
      "hourly": {
        "time": [1760097600, 1760101200, 1760104800, 1760108400],
        "temperature_2m": [19.0, 20.1, 21.4, 22.0],
        "weather_code": [0, 1, 2, 61],
        "precipitation_probability": [0, null, 10, 65]
      },
      "daily": {
        "time": [1760072400, 1760158800],
        "weather_code": [2, 95],
        "temperature_2m_max": [24.3, 26.0],
        "temperature_2m_min": [13.1, 15.2],
        "precipitation_probability_max": [10, null]
      }
    }
    """.data(using: .utf8)!

    func testDecodesAndMapsToDomainModel() throws {
        let now = Date(timeIntervalSince1970: 1760104800)
        let report = try OpenMeteoResponse.decode(json).makeReport(now: now)

        XCTAssertEqual(report.current.temperature, 21.4)
        XCTAssertEqual(report.current.humidity, 0.54, accuracy: 0.0001)
        XCTAssertEqual(report.current.condition, .partlyCloudy)
        XCTAssertTrue(report.current.isDaylight)

        // Hours more than an hour in the past are dropped.
        XCTAssertEqual(report.hourly.map(\.date.timeIntervalSince1970), [1760104800, 1760108400])
        XCTAssertEqual(report.hourly.last?.condition, .rain)
        XCTAssertEqual(report.hourly.last?.precipitationChance ?? 0, 0.65, accuracy: 0.0001)

        XCTAssertEqual(report.daily.count, 2)
        XCTAssertEqual(report.daily[1].condition, .thunderstorm)
        XCTAssertNil(report.daily[1].precipitationChance)
    }

    func testURLRequestsMetricUnixtimeForecast() throws {
        let url = OpenMeteoWeatherService.url(for: Coordinate(latitude: 30.25, longitude: -97.75))
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let query = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value) })

        XCTAssertEqual(url.host, "api.open-meteo.com")
        XCTAssertEqual(query["latitude"], "30.25")
        XCTAssertEqual(query["longitude"], "-97.75")
        XCTAssertEqual(query["timeformat"], "unixtime")
    }
}
