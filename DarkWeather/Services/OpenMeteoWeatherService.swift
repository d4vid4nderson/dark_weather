import Foundation

/// Free, keyless forecast API: https://open-meteo.com/en/docs
struct OpenMeteoWeatherService: WeatherService {
    var session: URLSession = .shared

    func weather(for coordinate: Coordinate) async throws -> WeatherReport {
        let (data, response) = try await session.data(from: Self.url(for: coordinate))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WeatherServiceError.badResponse(statusCode: http.statusCode)
        }
        return try OpenMeteoResponse.decode(data).makeReport(now: .now)
    }

    static func url(for coordinate: Coordinate) -> URL {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code,precipitation_probability"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            URLQueryItem(name: "timeformat", value: "unixtime"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "10"),
        ]
        return components.url!
    }
}

/// Wire format of the Open-Meteo forecast endpoint (columnar arrays).
struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let time: TimeInterval
        let temperature2m: Double
        let apparentTemperature: Double
        let relativeHumidity2m: Double
        let windSpeed10m: Double
        let weatherCode: Int
        let isDay: Int

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case relativeHumidity2m = "relative_humidity_2m"
            case windSpeed10m = "wind_speed_10m"
            case weatherCode = "weather_code"
            case isDay = "is_day"
        }
    }

    struct Hourly: Decodable {
        let time: [TimeInterval]
        let temperature2m: [Double]
        let weatherCode: [Int]
        let precipitationProbability: [Double?]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
            case precipitationProbability = "precipitation_probability"
        }
    }

    struct Daily: Decodable {
        let time: [TimeInterval]
        let weatherCode: [Int]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let precipitationProbabilityMax: [Double?]

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
        }
    }

    let current: Current
    let hourly: Hourly
    let daily: Daily

    /// Explicit CodingKeys rather than `.convertFromSnakeCase`, which turns
    /// `temperature_2m` into `temperature2M` and fails to match.
    static func decode(_ data: Data) throws -> OpenMeteoResponse {
        try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
    }

    /// Builds the domain model, keeping the next 24 hours of hourly data.
    func makeReport(now: Date) -> WeatherReport {
        let currentConditions = CurrentConditions(
            date: Date(timeIntervalSince1970: current.time),
            temperature: current.temperature2m,
            apparentTemperature: current.apparentTemperature,
            humidity: current.relativeHumidity2m / 100,
            windSpeed: current.windSpeed10m,
            condition: WeatherCondition(wmoCode: current.weatherCode),
            isDaylight: current.isDay == 1
        )

        let hourCount = min(hourly.time.count, hourly.temperature2m.count, hourly.weatherCode.count, hourly.precipitationProbability.count)
        let startOfHour = now.addingTimeInterval(-3600)
        let hours = (0..<hourCount)
            .map { i in
                HourlyForecast(
                    date: Date(timeIntervalSince1970: hourly.time[i]),
                    temperature: hourly.temperature2m[i],
                    condition: WeatherCondition(wmoCode: hourly.weatherCode[i]),
                    precipitationChance: hourly.precipitationProbability[i].map { $0 / 100 }
                )
            }
            .filter { $0.date > startOfHour }
            .prefix(24)

        let dayCount = min(daily.time.count, daily.weatherCode.count, daily.temperature2mMax.count, daily.temperature2mMin.count, daily.precipitationProbabilityMax.count)
        let days = (0..<dayCount).map { i in
            DailyForecast(
                date: Date(timeIntervalSince1970: daily.time[i]),
                high: daily.temperature2mMax[i],
                low: daily.temperature2mMin[i],
                condition: WeatherCondition(wmoCode: daily.weatherCode[i]),
                precipitationChance: daily.precipitationProbabilityMax[i].map { $0 / 100 }
            )
        }

        return WeatherReport(current: currentConditions, hourly: Array(hours), daily: days)
    }
}
