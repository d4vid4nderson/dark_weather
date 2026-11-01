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

    /// Lowercase label for table rows, at most 6 characters.
    var shortLabel: String {
        switch self {
        case .clear: "clear"
        case .partlyCloudy: "ptcldy"
        case .cloudy: "cloudy"
        case .fog: "fog"
        case .drizzle: "drizzl"
        case .rain: "rain"
        case .freezingRain: "frzrn"
        case .snow: "snow"
        case .thunderstorm: "storm"
        case .unknown: "--"
        }
    }

    /// Five-line, 13-column ASCII art for the current conditions panel.
    func asciiArt(isDaylight: Bool = true) -> [String] {
        let cloud = [
            #"     .--.    "#,
            #"  .-(    ).  "#,
            #" (___.__)__) "#,
        ]
        switch self {
        case .clear where isDaylight:
            return [
                #"   \  |  /   "#,
                #"    .---.    "#,
                #" --(     )-- "#,
                #"    '---'    "#,
                #"   /  |  \   "#,
            ]
        case .clear:
            return [
                #"     .--.    "#,
                #"    /  .'    "#,
                #"   |  |      "#,
                #"    \  '.    "#,
                #"     '--'    "#,
            ]
        case .partlyCloudy where isDaylight:
            return [
                #"   \  |  /   "#,
                #"  -( ).--.   "#,
                #"  .-(    ).  "#,
                #" (___.__)__) "#,
                #"             "#,
            ]
        case .partlyCloudy, .cloudy:
            return ["             "] + cloud + ["             "]
        case .fog:
            return [
                #"             "#,
                #" _ - _ - _ - "#,
                #"  _ - _ - _  "#,
                #" _ - _ - _ - "#,
                #"             "#,
            ]
        case .drizzle:
            return cloud + [
                #"   '  '  '   "#,
                #"  '  '  '    "#,
            ]
        case .rain:
            return cloud + [
                #"  / / / / /  "#,
                #" / / / / /   "#,
            ]
        case .freezingRain:
            return cloud + [
                #"  * / * / *  "#,
                #" / * / * /   "#,
            ]
        case .snow:
            return cloud + [
                #"   *  *  *   "#,
                #"  *  *  *    "#,
            ]
        case .thunderstorm:
            return cloud + [
                #"  /_ / /_ /  "#,
                #"   /  / /    "#,
            ]
        case .unknown:
            return [
                #"             "#,
                #"    .---.    "#,
                #"   (  ?  )   "#,
                #"    '---'    "#,
                #"             "#,
            ]
        }
    }
}
