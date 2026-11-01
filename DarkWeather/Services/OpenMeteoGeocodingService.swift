import Foundation

/// Free, keyless city search: https://open-meteo.com/en/docs/geocoding-api
///
/// Open-Meteo only matches the city name, so "austin, tx" searches for
/// "austin" and then keeps results whose state or country matches "tx".
struct OpenMeteoGeocodingService: PlaceSearching {
    var session: URLSession = .shared

    func search(_ query: String) async throws -> [Place] {
        let (name, qualifier) = Self.parse(query)
        guard name.count >= 2 else { return [] }

        let (data, response) = try await session.data(from: Self.url(for: name))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WeatherServiceError.badResponse(statusCode: http.statusCode)
        }
        return Self.filter(try Self.decode(data), qualifier: qualifier)
    }

    /// "Austin, TX" → ("Austin", "tx"); "Oslo" → ("Oslo", nil).
    static func parse(_ query: String) -> (name: String, qualifier: String?) {
        let parts = query.split(separator: ",", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let name = parts.first ?? ""
        let qualifier = parts.count > 1 && !parts[1].isEmpty ? parts[1].lowercased() : nil
        return (name, qualifier)
    }

    /// Keeps places whose state, country, or country code matches the
    /// qualifier. Prefix matches count, so "austin, t" already finds Texas.
    static func filter(_ places: [Place], qualifier: String?) -> [Place] {
        guard let qualifier else { return places }
        let stateName = USState.name(forAbbreviation: qualifier)?.lowercased()
        return places.filter { (place: Place) -> Bool in
            let region: String = place.region?.lowercased() ?? ""
            let country: String = place.country?.lowercased() ?? ""
            let countryCode: String = place.countryCode?.lowercased() ?? ""
            if !region.isEmpty && region.hasPrefix(qualifier) { return true }
            if !country.isEmpty && country.hasPrefix(qualifier) { return true }
            if countryCode == qualifier { return true }
            if let stateName, region == stateName { return true }
            return false
        }
    }

    static func url(for name: String) -> URL {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            // Enough candidates that the state filter usually has a match.
            URLQueryItem(name: "count", value: "20"),
            URLQueryItem(name: "language", value: Locale.current.language.languageCode?.identifier ?? "en"),
            URLQueryItem(name: "format", value: "json"),
        ]
        return components.url!
    }

    static func decode(_ data: Data) throws -> [Place] {
        struct Response: Decodable {
            struct Result: Decodable {
                let id: Int
                let name: String
                let latitude: Double
                let longitude: Double
                let admin1: String?
                let country: String?
                let countryCode: String?

                enum CodingKeys: String, CodingKey {
                    case id, name, latitude, longitude, admin1, country
                    case countryCode = "country_code"
                }
            }
            /// Omitted entirely when nothing matches.
            let results: [Result]?
        }

        let response = try JSONDecoder().decode(Response.self, from: data)
        return (response.results ?? []).map { result in
            Place(
                id: result.id,
                name: result.name,
                region: result.admin1,
                country: result.country,
                coordinate: Coordinate(latitude: result.latitude, longitude: result.longitude),
                countryCode: result.countryCode
            )
        }
    }
}
