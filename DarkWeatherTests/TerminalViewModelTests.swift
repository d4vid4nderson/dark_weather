import XCTest
@testable import DarkWeather

/// Records which coordinates were requested.
private final class SpyWeatherService: WeatherService, @unchecked Sendable {
    private(set) var requested: [Coordinate] = []

    func weather(for coordinate: Coordinate) async throws -> WeatherReport {
        requested.append(coordinate)
        return PreviewData.report()
    }
}

@MainActor
final class TerminalViewModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private let oslo = Place(id: 3143244, name: "Oslo", region: "Oslo", country: "Norway",
                             coordinate: Coordinate(latitude: 59.91, longitude: 10.75), countryCode: "NO")

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "TerminalViewModelTests-\(UUID().uuidString)")
    }

    private func makeViewModel(
        weather: WeatherService = PreviewWeatherService(),
        location: LocationProviding = PreviewLocationProvider(),
        search: PlaceSearching = PreviewPlaceSearch()
    ) -> TerminalViewModel {
        TerminalViewModel(weatherService: weather, locationProvider: location, placeSearch: search, defaults: defaults)
    }

    private func text(_ entry: TerminalViewModel.Entry) -> String {
        (entry.lines ?? []).map { $0.segments.map(\.text).joined() }.joined(separator: "\n")
    }

    func testStartsBlank() {
        XCTAssertEqual(makeViewModel().entries, [])
    }

    func testTypedCityPrintsForecastAndBecomesRecent() async {
        let spy = SpyWeatherService()
        let viewModel = makeViewModel(weather: spy)

        await viewModel.submit("  Austin, TX ")

        XCTAssertEqual(viewModel.entries.count, 1)
        let entry = viewModel.entries[0]
        XCTAssertEqual(entry.command, "weather austin, tx")
        XCTAssertTrue(text(entry).hasPrefix("# austin, tx"))
        XCTAssertNotNil(entry.summary)
        XCTAssertFalse(entry.hasAnimated)
        XCTAssertEqual(spy.requested, [PreviewData.coordinate])
        XCTAssertEqual(viewModel.recents, [PreviewData.place])
        // Recents survive a relaunch.
        XCTAssertEqual(makeViewModel().recents, [PreviewData.place])
    }

    func testUnknownCityPrintsError() async {
        let viewModel = makeViewModel(search: PreviewPlaceSearch(results: []))

        await viewModel.submit("nowhereville")

        XCTAssertTrue(text(viewModel.entries[0]).hasPrefix("error: no city matching 'nowhereville'"))
        XCTAssertEqual(viewModel.recents, [])
    }

    func testTappedPlaceSkipsSearchAndMovesToFrontOfRecents() async {
        let spy = SpyWeatherService()
        let viewModel = makeViewModel(weather: spy)
        await viewModel.run(oslo)
        await viewModel.run(PreviewData.place)

        await viewModel.run(oslo)

        XCTAssertEqual(spy.requested.last, oslo.coordinate)
        XCTAssertEqual(viewModel.entries.last?.command, "weather oslo, norway")
        XCTAssertEqual(viewModel.recents, [oslo, PreviewData.place])
    }

    func testRecentsAreCapped() async {
        let viewModel = makeViewModel()
        for id in 1...(TerminalViewModel.maxRecents + 2) {
            await viewModel.run(Place(id: id, name: "City \(id)", region: nil, country: nil, coordinate: PreviewData.coordinate))
        }
        XCTAssertEqual(viewModel.recents.count, TerminalViewModel.maxRecents)
        XCTAssertEqual(viewModel.recents.first?.id, TerminalViewModel.maxRecents + 2)
    }

    func testHereUsesGPS() async {
        let viewModel = makeViewModel(location: PreviewLocationProvider(name: "Austin"))

        await viewModel.submit("here")

        XCTAssertEqual(viewModel.entries[0].command, "weather --here")
        XCTAssertTrue(text(viewModel.entries[0]).hasPrefix("# austin"))
    }

    func testHereWithLocationDeniedSaysToType() async {
        let viewModel = makeViewModel(location: PreviewLocationProvider(result: .failure(LocationError.denied)))

        await viewModel.runCurrentLocation()

        XCTAssertTrue(text(viewModel.entries[0]).hasPrefix("error: location access is off"))
    }

    func testClearAndHelp() async {
        let viewModel = makeViewModel()
        await viewModel.submit("austin")
        await viewModel.submit("help")
        XCTAssertEqual(viewModel.entries.count, 2)
        XCTAssertEqual(viewModel.entries[1].lines, TerminalViewModel.helpLines)

        await viewModel.submit("clear")

        XCTAssertEqual(viewModel.entries, [])
    }

    func testBlankInputDoesNothing() async {
        let viewModel = makeViewModel()
        await viewModel.submit("   ")
        XCTAssertEqual(viewModel.entries, [])
    }

    func testScrollbackIsCapped() async {
        let viewModel = makeViewModel()
        for _ in 0..<(TerminalViewModel.maxEntries + 3) {
            await viewModel.submit("help")
        }
        XCTAssertEqual(viewModel.entries.count, TerminalViewModel.maxEntries)
    }

    func testMarkAnimatedStopsReplay() async {
        let viewModel = makeViewModel()
        await viewModel.submit("help")

        viewModel.markAnimated(viewModel.entries[0].id)

        XCTAssertTrue(viewModel.entries[0].hasAnimated)
    }

    func testSuggestionsNeedTwoCharacters() async {
        let viewModel = makeViewModel()

        await viewModel.updateSuggestions(for: "a")
        XCTAssertEqual(viewModel.suggestions, [])

        await viewModel.updateSuggestions(for: "au")
        XCTAssertEqual(viewModel.suggestions, [PreviewData.place])
    }
}
