import Foundation

/// Canned data for SwiftUI previews and unit tests.
enum PreviewData {
    static let coordinate = Coordinate(latitude: 30.2672, longitude: -97.7431)
    static let place = Place(id: 4671654, name: "Austin", region: "Texas", country: "United States", coordinate: coordinate, countryCode: "US")

    static func report(now: Date = .now) -> WeatherReport {
        let calendar = Calendar.current
        let hour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let day = calendar.startOfDay(for: now)
        let conditions: [WeatherCondition] = [.clear, .partlyCloudy, .cloudy, .rain, .thunderstorm, .drizzle, .clear]

        return WeatherReport(
            current: CurrentConditions(
                date: now, temperature: 22, apparentTemperature: 21,
                humidity: 0.54, windSpeed: 12, condition: .partlyCloudy, isDaylight: true
            ),
            hourly: (0..<24).map { (i: Int) -> HourlyForecast in
                let temperature: Double = 22.0 - Double(i % 12) * 0.6
                let chance: Double? = i % 4 == 3 ? 0.4 : nil
                return HourlyForecast(
                    date: calendar.date(byAdding: .hour, value: i, to: hour)!,
                    temperature: temperature,
                    condition: conditions[i % conditions.count],
                    precipitationChance: chance
                )
            },
            daily: (0..<10).map { (i: Int) -> DailyForecast in
                let high: Double = 24.0 + Double(i % 3)
                let low: Double = 13.0 + Double(i % 2)
                let chance: Double = i % 3 == 0 ? 0.3 : 0.0
                return DailyForecast(
                    date: calendar.date(byAdding: .day, value: i, to: day)!,
                    high: high,
                    low: low,
                    condition: conditions[i % conditions.count],
                    precipitationChance: chance
                )
            }
        )
    }
}

struct PreviewWeatherService: WeatherService {
    var result: Result<WeatherReport, Error> = .success(PreviewData.report())

    func weather(for coordinate: Coordinate) async throws -> WeatherReport {
        try result.get()
    }
}

struct PreviewLocationProvider: LocationProviding {
    var result: Result<Coordinate, Error> = .success(PreviewData.coordinate)
    var name: String? = "Austin"

    func currentLocation() async throws -> Coordinate { try result.get() }
    func placeName(for coordinate: Coordinate) async -> String? { name }
}

struct PreviewPlaceSearch: PlaceSearching {
    var results: [Place] = [PreviewData.place]

    func search(_ query: String) async throws -> [Place] { results }
}
