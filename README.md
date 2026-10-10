# Dark Weather

A SwiftUI weather app for iOS, styled like a terminal: dark gray background, monospaced text, ASCII-art conditions in the style of [wttr.in](https://wttr.in), and forecasts printed as text tables.

You still use it by tapping. Pull down to refresh; there's nothing to type.

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
  ViewModels/   WeatherViewModel (@Observable, idle → loading → loaded/failed)
  Views/        SwiftUI screens and components
  Theme/        Terminal palette, prompt/section/cursor components, formatters
DarkWeatherTests/
```

- **Data:** `OpenMeteoWeatherService` calls [Open-Meteo](https://open-meteo.com), which is free and needs no API key. To switch to WeatherKit, add another `WeatherService` implementation and change the wiring in `DarkWeatherApp.swift`. WeatherKit requires a paid developer account, the WeatherKit capability, and an Apple Weather attribution in the UI.
- **Location:** GPS first. If the user denies location access, the app shows a city search instead, using Open-Meteo's free geocoding API. The picked city is saved in `UserDefaults` and used instead of GPS until the user taps `[ use gps ]`. Tapping the `$ weather <city>` line opens the search at any time.
- **Units:** models store °C and km/h. `Format` converts them to the user's locale, so US users see °F and mph.
- **Theme:** colors and the monospaced font live in `Theme/Theme.swift`. Table columns are built by padding strings, so they only line up in a monospaced font. ASCII art is in `WeatherCondition.asciiArt`; each piece must be 5 lines of 13 columns, and a test checks this.
- **Previews and tests** use `PreviewWeatherService` and `PreviewLocationProvider` (`Services/PreviewData.swift`).

## Roadmap ideas

- Saved locations and search
- Widgets (WidgetKit) and a Live Activity for incoming rain
- Weather alerts and minute-by-minute precipitation
- Settings for unit overrides
