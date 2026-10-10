import Foundation

/// Source of forecast data. Swap `OpenMeteoWeatherService` for a WeatherKit
/// implementation without touching the UI.
protocol WeatherService: Sendable {
    func weather(for coordinate: Coordinate) async throws -> WeatherReport
}

/// Source of the device's location and a human-readable name for it.
protocol LocationProviding {
    @MainActor func currentLocation() async throws -> Coordinate
    @MainActor func placeName(for coordinate: Coordinate) async -> String?
}

enum WeatherServiceError: LocalizedError {
    case badResponse(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): "The weather service returned an error (\(code))."
        }
    }
}
