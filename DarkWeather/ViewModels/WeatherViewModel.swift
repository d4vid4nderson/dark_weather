import Foundation
import Observation

@MainActor
@Observable
final class WeatherViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(WeatherReport)
        case failed(message: String)
    }

    private(set) var state: State = .idle
    private(set) var placeName: String?

    private let weatherService: WeatherService
    private let locationProvider: LocationProviding

    init(weatherService: WeatherService, locationProvider: LocationProviding) {
        self.weatherService = weatherService
        self.locationProvider = locationProvider
    }

    func refresh() async {
        // Keep showing stale data during pull-to-refresh instead of a spinner.
        if case .loaded = state {} else { state = .loading }

        do {
            let coordinate = try await locationProvider.currentLocation()
            let report = try await weatherService.weather(for: coordinate)
            placeName = await locationProvider.placeName(for: coordinate)
            state = .loaded(report)
        } catch is CancellationError {
            // A newer refresh superseded this one.
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
