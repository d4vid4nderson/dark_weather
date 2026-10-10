import Foundation

struct Coordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double
}

/// A named location picked through city search.
struct Place: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let region: String?
    let country: String?
    let coordinate: Coordinate

    /// e.g. "Austin, Texas, United States"
    var displayName: String {
        [name, region, country].compactMap { $0 }.joined(separator: ", ")
    }
}

/// Everything the UI needs for one location. Temperatures are Celsius and
/// wind speeds km/h; formatting converts to the user's locale.
struct WeatherReport: Sendable, Equatable {
    let current: CurrentConditions
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
}

struct CurrentConditions: Sendable, Equatable {
    let date: Date
    let temperature: Double
    let apparentTemperature: Double
    /// 0...1
    let humidity: Double
    let windSpeed: Double
    let condition: WeatherCondition
    let isDaylight: Bool
}

struct HourlyForecast: Identifiable, Sendable, Equatable {
    var id: Date { date }
    let date: Date
    let temperature: Double
    let condition: WeatherCondition
    /// 0...1, nil when the provider has no value.
    let precipitationChance: Double?
}

struct DailyForecast: Identifiable, Sendable, Equatable {
    var id: Date { date }
    let date: Date
    let high: Double
    let low: Double
    let condition: WeatherCondition
    /// 0...1, nil when the provider has no value.
    let precipitationChance: Double?
}
