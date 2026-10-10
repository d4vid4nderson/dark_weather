# Dark Weather

A dark-themed iOS weather app built with SwiftUI.

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
  Theme/        Colors, the Card container, and locale-aware formatters
DarkWeatherTests/
```

- **Data:** `OpenMeteoWeatherService` calls [Open-Meteo](https://open-meteo.com), which is free and needs no API key. To switch to WeatherKit, add another `WeatherService` implementation and change the wiring in `DarkWeatherApp.swift`. WeatherKit requires a paid developer account, the WeatherKit capability, and an Apple Weather attribution in the UI.
- **Units:** models store °C and km/h. `Format` converts them to the user's locale, so US users see °F and mph.
- **Previews and tests** use `PreviewWeatherService` and `PreviewLocationProvider` (`Services/PreviewData.swift`).

## Roadmap ideas

- Saved locations and search
- Widgets (WidgetKit) and a Live Activity for incoming rain
- Weather alerts and minute-by-minute precipitation
- Settings for unit overrides
