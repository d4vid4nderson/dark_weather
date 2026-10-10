import Foundation

struct Coordinate: Hashable, Sendable {
    let latitude: Double
    let longitude: Double
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
