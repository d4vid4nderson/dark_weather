import Foundation

/// Canned data for SwiftUI previews and unit tests.
enum PreviewData {
    static let coordinate = Coordinate(latitude: 30.2672, longitude: -97.7431)

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
            hourly: (0..<24).map { i in
                HourlyForecast(
                    date: calendar.date(byAdding: .hour, value: i, to: hour)!,
                    temperature: 22 - Double(i % 12) * 0.6,
                    condition: conditions[i % conditions.count],
                    precipitationChance: i % 4 == 3 ? 0.4 : nil
                )
            },
            daily: (0..<10).map { i in
                DailyForecast(
                    date: calendar.date(byAdding: .day, value: i, to: day)!,
                    high: 24 + Double(i % 3),
                    low: 13 + Double(i % 2),
                    condition: conditions[i % conditions.count],
                    precipitationChance: i % 3 == 0 ? 0.3 : 0
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
