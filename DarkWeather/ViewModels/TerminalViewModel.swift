import Foundation
import Observation

/// Runs `weather <city>` commands and keeps the scrollback.
@MainActor
@Observable
final class TerminalViewModel {
    struct Entry: Identifiable, Equatable {
        enum Content: Equatable {
            case running
            /// `summary` is spoken by VoiceOver in place of the lines, when set.
            case lines([TerminalLine], summary: String?)
            /// `weather --recent`: tappable rows, as they stood when printed.
            case recents([RecentPlace])
        }

        let id = UUID()
        /// Echoed after the `$ ` prompt.
        let command: String
        var content: Content = .running
        /// Only the newest output types itself out, and only once.
        var hasAnimated = false

        var lines: [TerminalLine]? {
            if case .lines(let lines, _) = content { lines } else { nil }
        }

        var summary: String? {
            if case .lines(_, let summary) = content { summary } else { nil }
        }
    }

    /// A city looked up before, and when.
    struct RecentPlace: Codable, Equatable, Identifiable {
        let place: Place
        let lastChecked: Date
        var id: Place.ID { place.id }
    }

    static let maxEntries = 20
    static let maxRecents = 5

    private(set) var entries: [Entry] = []
    /// Most recent first.
    private(set) var recents: [RecentPlace] = []
    /// City matches for what's being typed.
    private(set) var suggestions: [Place] = []

    private let weatherService: WeatherService
    private let locationProvider: LocationProviding
    private let placeSearch: PlaceSearching
    private let defaults: UserDefaults
    private let now: () -> Date
    private static let recentsKey = "recentLookups"

    init(
        weatherService: WeatherService,
        locationProvider: LocationProviding,
        placeSearch: PlaceSearching,
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.weatherService = weatherService
        self.locationProvider = locationProvider
        self.placeSearch = placeSearch
        self.defaults = defaults
        self.now = now
        if let data = defaults.data(forKey: Self.recentsKey),
           let saved = try? JSONDecoder().decode([RecentPlace].self, from: data) {
            recents = saved
        }
    }

    /// Handles what was typed after `$ weather `.
    func submit(_ input: String) async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        suggestions = []

        switch text.lowercased() {
        case "clear":
            clearScreen()
        case "recent", "--recent":
            showRecents()
        case "help":
            let id = begin("weather \(text)")
            finish(id, lines: Self.helpLines)
        case "here", "--here":
            await runCurrentLocation()
        default:
            await runCity(text)
        }
    }

    /// A tapped suggestion: no search needed.
    func run(_ place: Place) async {
        suggestions = []
        let id = begin("weather \(place.shortName.lowercased())")
        remember(place)
        await fetch(id, coordinate: place.coordinate, placeName: place.shortName)
    }

    func runCurrentLocation() async {
        suggestions = []
        let id = begin("weather --here")
        do {
            let coordinate = try await locationProvider.currentLocation()
            let name = await locationProvider.placeName(for: coordinate) ?? "current location"
            await fetch(id, coordinate: coordinate, placeName: name)
        } catch LocationError.denied {
            fail(id, "location access is off. type a city instead, e.g. austin, tx")
        } catch {
            fail(id, error.localizedDescription)
        }
    }

    /// Prints the recent cities as a tappable list.
    func showRecents() {
        suggestions = []
        let id = begin("weather --recent")
        if recents.isEmpty {
            finish(id, lines: [TerminalLine("no recent cities. type a city, state.", .dim)])
        } else {
            setContent(id, .recents(recents))
        }
    }

    func clearScreen() {
        entries.removeAll()
    }

    /// Deletes the saved cities and clears the screen.
    func forgetAll() {
        recents = []
        defaults.removeObject(forKey: Self.recentsKey)
        clearScreen()
    }

    func updateSuggestions(for query: String) async {
        guard query.trimmingCharacters(in: .whitespaces).count >= 2 else {
            suggestions = []
            return
        }
        do {
            suggestions = Array(try await placeSearch.search(query).prefix(5))
        } catch {
            // Suggestions are best-effort; keep whatever was showing.
        }
    }

    func markAnimated(_ id: Entry.ID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].hasAnimated = true
    }

    // MARK: - Private

    private func runCity(_ query: String) async {
        let id = begin("weather \(query.lowercased())")
        do {
            guard let place = try await placeSearch.search(query).first else {
                fail(id, "no city matching '\(query)'. try: city, state")
                return
            }
            remember(place)
            await fetch(id, coordinate: place.coordinate, placeName: place.shortName)
        } catch {
            fail(id, error.localizedDescription)
        }
    }

    private func fetch(_ id: Entry.ID, coordinate: Coordinate, placeName: String) async {
        do {
            let report = try await weatherService.weather(for: coordinate)
            finish(
                id,
                lines: ForecastPrinter.lines(for: report, placeName: placeName),
                summary: ForecastPrinter.summary(for: report, placeName: placeName)
            )
        } catch {
            fail(id, error.localizedDescription)
        }
    }

    private func begin(_ command: String) -> Entry.ID {
        let entry = Entry(command: command)
        entries.append(entry)
        if entries.count > Self.maxEntries {
            entries.removeFirst(entries.count - Self.maxEntries)
        }
        return entry.id
    }

    private func finish(_ id: Entry.ID, lines: [TerminalLine], summary: String? = nil) {
        setContent(id, .lines(lines, summary: summary))
    }

    private func setContent(_ id: Entry.ID, _ content: Entry.Content) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].content = content
    }

    private func fail(_ id: Entry.ID, _ message: String) {
        finish(id, lines: [TerminalLine("error: \(message)", .error)])
    }

    private func remember(_ place: Place) {
        recents.removeAll { $0.id == place.id }
        recents.insert(RecentPlace(place: place, lastChecked: now()), at: 0)
        recents = Array(recents.prefix(Self.maxRecents))
        defaults.set(try? JSONEncoder().encode(recents), forKey: Self.recentsKey)
    }

    static let helpLines: [TerminalLine] = [
        TerminalLine("usage: weather <city>[, <state or country>]"),
        .blank,
        TerminalLine([.init(text: "  austin, tx  ", style: .plain), .init(text: "a city", style: .dim)]),
        TerminalLine([.init(text: "  here        ", style: .plain), .init(text: "use gps", style: .dim)]),
        TerminalLine([.init(text: "  recent      ", style: .plain), .init(text: "cities you've checked", style: .dim)]),
        TerminalLine([.init(text: "  clear       ", style: .plain), .init(text: "clear the screen", style: .dim)]),
        TerminalLine([.init(text: "  help        ", style: .plain), .init(text: "show this", style: .dim)]),
    ]
}
