import Foundation
import Observation

@MainActor
@Observable
final class WeatherViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(WeatherReport)
        /// Location access is denied and no city has been picked yet.
        case needsPlace(reason: String)
        case failed(message: String)
    }

    private(set) var state: State = .idle
    private(set) var placeName: String?
    /// A city picked through search. When set it's used instead of GPS.
    private(set) var selectedPlace: Place?
    private(set) var searchResults: [Place] = []
    private(set) var searchError: String?

    private let weatherService: WeatherService
    private let locationProvider: LocationProviding
    private let placeSearch: PlaceSearching
    private let defaults: UserDefaults
    private static let selectedPlaceKey = "selectedPlace"

    init(
        weatherService: WeatherService,
        locationProvider: LocationProviding,
        placeSearch: PlaceSearching,
        defaults: UserDefaults = .standard
    ) {
        self.weatherService = weatherService
        self.locationProvider = locationProvider
        self.placeSearch = placeSearch
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.selectedPlaceKey) {
            selectedPlace = try? JSONDecoder().decode(Place.self, from: data)
        }
    }

    func refresh() async {
        // Keep showing stale data during pull-to-refresh instead of a spinner.
        if case .loaded = state {} else { state = .loading }

        do {
            let coordinate: Coordinate
            if let selectedPlace {
                coordinate = selectedPlace.coordinate
                placeName = selectedPlace.name
            } else {
                coordinate = try await locationProvider.currentLocation()
                placeName = await locationProvider.placeName(for: coordinate)
            }
            state = .loaded(try await weatherService.weather(for: coordinate))
        } catch LocationError.denied {
            state = .needsPlace(reason: LocationError.denied.localizedDescription)
        } catch is CancellationError {
            // A newer refresh superseded this one.
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    func search(_ query: String) async {
        do {
            searchResults = try await placeSearch.search(query)
            searchError = nil
        } catch is CancellationError {
            // Superseded by a newer keystroke.
        } catch let error as URLError where error.code == .cancelled {
            // Superseded by a newer keystroke.
        } catch {
            searchResults = []
            searchError = error.localizedDescription
        }
    }

    /// Switches to a searched city and remembers it across launches.
    func select(_ place: Place) async {
        selectedPlace = place
        defaults.set(try? JSONEncoder().encode(place), forKey: Self.selectedPlaceKey)
        searchResults = []
        state = .loading
        await refresh()
    }

    /// Forgets the searched city and goes back to GPS.
    func useCurrentLocation() async {
        selectedPlace = nil
        defaults.removeObject(forKey: Self.selectedPlaceKey)
        state = .loading
        await refresh()
    }
}
