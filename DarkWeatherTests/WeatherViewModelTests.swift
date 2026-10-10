import XCTest
@testable import DarkWeather

/// Records which coordinate the view model asked for.
private final class SpyWeatherService: WeatherService, @unchecked Sendable {
    private(set) var requested: [Coordinate] = []

    func weather(for coordinate: Coordinate) async throws -> WeatherReport {
        requested.append(coordinate)
        return PreviewData.report()
    }
}

@MainActor
final class WeatherViewModelTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "WeatherViewModelTests-\(UUID().uuidString)")
    }

    private func makeViewModel(
        weather: WeatherService = PreviewWeatherService(),
        location: LocationProviding = PreviewLocationProvider()
    ) -> WeatherViewModel {
        WeatherViewModel(weatherService: weather, locationProvider: location, placeSearch: PreviewPlaceSearch(), defaults: defaults)
    }

    func testRefreshLoadsReportAndPlaceName() async {
        let report = PreviewData.report()
        let viewModel = makeViewModel(
            weather: PreviewWeatherService(result: .success(report)),
            location: PreviewLocationProvider(name: "Austin")
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .loaded(report))
        XCTAssertEqual(viewModel.placeName, "Austin")
    }

    func testLocationDeniedAsksForCity() async {
        let viewModel = makeViewModel(location: PreviewLocationProvider(result: .failure(LocationError.denied)))

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .needsPlace(reason: LocationError.denied.localizedDescription))
    }

    func testOtherLocationFailureIsAnError() async {
        let viewModel = makeViewModel(location: PreviewLocationProvider(result: .failure(LocationError.unavailable)))

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .failed(message: LocationError.unavailable.localizedDescription))
    }

    func testServiceErrorSurfacesError() async {
        let viewModel = makeViewModel(weather: PreviewWeatherService(result: .failure(WeatherServiceError.badResponse(statusCode: 500))))

        await viewModel.refresh()

        guard case .failed = viewModel.state else { return XCTFail("Expected failure, got \(viewModel.state)") }
    }

    func testSelectedPlaceIsUsedInsteadOfGPSAndRemembered() async {
        let spy = SpyWeatherService()
        let place = Place(id: 1, name: "Oslo", region: nil, country: "Norway", coordinate: Coordinate(latitude: 59.91, longitude: 10.75))
        let viewModel = makeViewModel(weather: spy, location: PreviewLocationProvider(result: .failure(LocationError.denied)))

        await viewModel.select(place)

        XCTAssertEqual(spy.requested, [place.coordinate])
        XCTAssertEqual(viewModel.placeName, "Oslo")
        guard case .loaded = viewModel.state else { return XCTFail("Expected loaded, got \(viewModel.state)") }

        // A fresh launch picks the saved city back up.
        XCTAssertEqual(makeViewModel().selectedPlace, place)
    }

    func testUseCurrentLocationForgetsSelectedPlace() async {
        let spy = SpyWeatherService()
        let here = Coordinate(latitude: 1, longitude: 2)
        let viewModel = makeViewModel(weather: spy, location: PreviewLocationProvider(result: .success(here)))
        await viewModel.select(PreviewData.place)

        await viewModel.useCurrentLocation()

        XCTAssertNil(viewModel.selectedPlace)
        XCTAssertNil(makeViewModel().selectedPlace)
        XCTAssertEqual(spy.requested, [PreviewData.coordinate, here])
    }

    func testSearchPublishesResults() async {
        let viewModel = makeViewModel()

        await viewModel.search("aus")

        XCTAssertEqual(viewModel.searchResults, [PreviewData.place])
        XCTAssertNil(viewModel.searchError)
    }
}
