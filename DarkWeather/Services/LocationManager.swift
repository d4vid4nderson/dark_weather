import CoreLocation

enum LocationError: LocalizedError {
    case denied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied: "Location access is off. Enable it in Settings to see your local forecast."
        case .unavailable: "Couldn't determine your location."
        }
    }
}

/// One-shot location lookup wrapped in async/await.
@MainActor
final class LocationManager: NSObject, LocationProviding {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var pending: CheckedContinuation<Coordinate, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func currentLocation() async throws -> Coordinate {
        if case .denied = manager.authorizationStatus { throw LocationError.denied }
        if case .restricted = manager.authorizationStatus { throw LocationError.denied }

        return try await withCheckedThrowingContinuation { continuation in
            pending?.resume(throwing: CancellationError())
            pending = continuation
            if manager.authorizationStatus == .notDetermined {
                // Resumes in locationManagerDidChangeAuthorization.
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    func placeName(for coordinate: Coordinate) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try? await geocoder.reverseGeocodeLocation(location).first
        return placemark?.locality ?? placemark?.name
    }

    private func finish(_ result: Result<Coordinate, Error>) {
        pending?.resume(with: result)
        pending = nil
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard pending != nil else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways: self.manager.requestLocation()
            case .denied, .restricted: finish(.failure(LocationError.denied))
            default: break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        Task { @MainActor in finish(.success(coordinate)) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in finish(.failure(LocationError.unavailable)) }
    }
}
