# Dark Weather

A SwiftUI weather app for iOS that works like a terminal. It opens to a blank screen with a blinking `$ weather █` prompt. Type a city (`austin, tx`) or tap a suggestion above the keyboard, and the forecast prints down the screen: ASCII-art conditions in the style of [wttr.in](https://wttr.in), then hourly, 10-day and detail tables.

- **Suggestions:** `[ here ]` uses GPS, then up to five recent cities. While typing, the row shows matching cities instead.
- **Scrollback:** each lookup prints below the last one, like a real terminal. `clear` wipes the screen and `help` lists the commands.
- **Typing effect:** new output types itself out in about 1.5 seconds. Tap to skip it. It's off when Reduce Motion is on, and VoiceOver reads a one-sentence summary instead of the tables.

## Requirements

- Xcode 15 or later (iOS 17 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Getting started

The Xcode project is generated from `project.yml` and isn't checked in.

```sh
xcodegen generate
open DarkWeather.xcodeproj
```

Run `xcodegen generate` again after you add or remove files. Before you run the app on a device, set your team and bundle ID (currently `com.example.darkweather`) in `project.yml`.

## Architecture

```
DarkWeather/
  App/          App entry point and dependency wiring
  Models/       Domain types (WeatherReport, WeatherCondition, …), all metric
  Services/     WeatherService + LocationProviding protocols and implementations
  ViewModels/   TerminalViewModel: runs commands, keeps scrollback and recents
  Views/        TerminalView (prompt + scrollback), SuggestionBar, typewriter output
  Theme/        Palette, cursor, ForecastPrinter (forecast → terminal lines), formatters
DarkWeatherTests/
```

- **Data:** `OpenMeteoWeatherService` calls [Open-Meteo](https://open-meteo.com), which is free and needs no API key. To switch to WeatherKit, add another `WeatherService` implementation and change the wiring in `DarkWeatherApp.swift`. WeatherKit requires a paid developer account, the WeatherKit capability, and an Apple Weather attribution in the UI.
- **Location:** GPS is only used when the user taps `[ here ]` or types `here`, so the permission prompt appears then, not at launch. Typed cities go through Open-Meteo's free geocoding API. Open-Meteo matches only the city name, so `OpenMeteoGeocodingService` filters the results by the part after the comma (a state abbreviation, state name or country).
- **Units:** models store °C and km/h. `Format` converts them to the user's locale, so US users see °F and mph.
- **Theme:** colors and the monospaced font live in `Theme/Theme.swift`. `ForecastPrinter` turns a forecast into `TerminalLine`s (colored runs of text). Columns are built by padding strings, so they only line up in a monospaced font. ASCII art is in `WeatherCondition.asciiArt`; each piece must be 5 lines of 13 columns, and a test checks this.
- **Previews and tests** use `PreviewWeatherService` and `PreviewLocationProvider` (`Services/PreviewData.swift`).

## Roadmap ideas

- Pinned favorite cities
- Widgets (WidgetKit) and a Live Activity for incoming rain
- Weather alerts and minute-by-minute precipitation
- Settings for unit overrides
