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
        XCTAssertEqual(places[0].countryCode, "US")
        XCTAssertEqual(places[0].shortName, "Austin, TX")
        XCTAssertEqual(places[1].displayName, "Austin")
    }

    func testParseSplitsCityFromQualifier() {
        XCTAssertTrue(OpenMeteoGeocodingService.parse(" Austin , TX ") == ("Austin", "tx"))
        XCTAssertTrue(OpenMeteoGeocodingService.parse("Oslo") == ("Oslo", nil))
        XCTAssertTrue(OpenMeteoGeocodingService.parse("Oslo,") == ("Oslo", nil))
    }

    func testFilterMatchesStateAbbreviationNamePrefixAndCountry() {
        let texas = Place(id: 1, name: "Austin", region: "Texas", country: "United States",
                          coordinate: Coordinate(latitude: 30.27, longitude: -97.74), countryCode: "US")
        let minnesota = Place(id: 2, name: "Austin", region: "Minnesota", country: "United States",
                              coordinate: Coordinate(latitude: 43.67, longitude: -92.97), countryCode: "US")
        let places = [texas, minnesota]

        XCTAssertEqual(OpenMeteoGeocodingService.filter(places, qualifier: "tx"), [texas])
        XCTAssertEqual(OpenMeteoGeocodingService.filter(places, qualifier: "minn"), [minnesota])
        XCTAssertEqual(OpenMeteoGeocodingService.filter(places, qualifier: "us"), places)
        XCTAssertEqual(OpenMeteoGeocodingService.filter(places, qualifier: "united"), places)
        XCTAssertEqual(OpenMeteoGeocodingService.filter(places, qualifier: "zz"), [])
        XCTAssertEqual(OpenMeteoGeocodingService.filter(places, qualifier: nil), places)
    }

    func testShortNameOutsideTheUSUsesCountry() {
        let oslo = Place(id: 3, name: "Oslo", region: "Oslo", country: "Norway",
                         coordinate: Coordinate(latitude: 59.91, longitude: 10.75), countryCode: "NO")
        XCTAssertEqual(oslo.shortName, "Oslo, Norway")
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
