import XCTest
@testable import DarkWeather

final class OpenMeteoGeocodingTests: XCTestCase {
    func testDecodesResults() throws {
        let json = """
        {
          "results": [
            { "id": 4671654, "name": "Austin", "latitude": 30.26715, "longitude": -97.74306,
              "country_code": "US", "admin1": "Texas", "country": "United States" },
            { "id": 5016450, "name": "Austin", "latitude": 43.66663, "longitude": -92.97464 }
          ],
          "generationtime_ms": 0.9
        }
        """.data(using: .utf8)!

        let places = try OpenMeteoGeocodingService.decode(json)

        XCTAssertEqual(places.count, 2)
        XCTAssertEqual(places[0].displayName, "Austin, Texas, United States")
        XCTAssertEqual(places[0].coordinate, Coordinate(latitude: 30.26715, longitude: -97.74306))
        XCTAssertEqual(places[1].displayName, "Austin")
    }

    func testNoMatchesDecodesToEmpty() throws {
        let json = #"{ "generationtime_ms": 0.4 }"#.data(using: .utf8)!

        XCTAssertEqual(try OpenMeteoGeocodingService.decode(json), [])
    }

    func testShortQueriesSkipTheNetwork() async throws {
        let results = try await OpenMeteoGeocodingService().search(" a ")
        XCTAssertEqual(results, [])
    }
}
