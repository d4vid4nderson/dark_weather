import Foundation

/// Free, keyless city search: https://open-meteo.com/en/docs/geocoding-api
struct OpenMeteoGeocodingService: PlaceSearching {
    var session: URLSession = .shared

    func search(_ query: String) async throws -> [Place] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let (data, response) = try await session.data(from: Self.url(for: trimmed))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WeatherServiceError.badResponse(statusCode: http.statusCode)
        }
        return try Self.decode(data)
    }

    static func url(for query: String) -> URL {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "8"),
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
                coordinate: Coordinate(latitude: result.latitude, longitude: result.longitude)
            )
        }
    }
}
