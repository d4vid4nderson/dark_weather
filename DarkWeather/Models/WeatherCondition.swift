import Foundation

enum WeatherCondition: String, Sendable, CaseIterable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case drizzle
    case rain
    case freezingRain
    case snow
    case thunderstorm
    case unknown

    /// Maps a WMO weather interpretation code (as used by Open-Meteo).
    init(wmoCode: Int) {
        switch wmoCode {
        case 0: self = .clear
        case 1, 2: self = .partlyCloudy
        case 3: self = .cloudy
        case 45, 48: self = .fog
        case 51, 53, 55: self = .drizzle
        case 56, 57, 66, 67: self = .freezingRain
        case 61, 63, 65, 80, 81, 82: self = .rain
        case 71, 73, 75, 77, 85, 86: self = .snow
        case 95, 96, 99: self = .thunderstorm
        default: self = .unknown
        }
    }

    var description: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .freezingRain: "Freezing Rain"
        case .snow: "Snow"
        case .thunderstorm: "Thunderstorms"
        case .unknown: "—"
        }
    }

    func symbolName(isDaylight: Bool = true) -> String {
        switch self {
        case .clear: isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy: isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .freezingRain: "cloud.sleet.fill"
        case .snow: "cloud.snow.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .unknown: "questionmark.circle"
        }
    }
}
