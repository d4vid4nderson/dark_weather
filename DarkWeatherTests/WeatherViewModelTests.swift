import XCTest
@testable import DarkWeather

@MainActor
final class WeatherViewModelTests: XCTestCase {
    func testRefreshLoadsReportAndPlaceName() async {
        let report = PreviewData.report()
        let viewModel = WeatherViewModel(
            weatherService: PreviewWeatherService(result: .success(report)),
            locationProvider: PreviewLocationProvider(name: "Austin")
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .loaded(report))
        XCTAssertEqual(viewModel.placeName, "Austin")
    }

    func testLocationDeniedSurfacesError() async {
        let viewModel = WeatherViewModel(
            weatherService: PreviewWeatherService(),
            locationProvider: PreviewLocationProvider(result: .failure(LocationError.denied))
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .failed(message: LocationError.denied.localizedDescription))
    }

    func testServiceErrorSurfacesError() async {
        let viewModel = WeatherViewModel(
            weatherService: PreviewWeatherService(result: .failure(WeatherServiceError.badResponse(statusCode: 500))),
            locationProvider: PreviewLocationProvider()
        )

        await viewModel.refresh()

        guard case .failed = viewModel.state else { return XCTFail("Expected failure, got \(viewModel.state)") }
    }
}
