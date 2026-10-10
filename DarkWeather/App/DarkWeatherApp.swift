import SwiftUI

@main
struct DarkWeatherApp: App {
    @State private var viewModel = WeatherViewModel(
        weatherService: OpenMeteoWeatherService(),
        locationProvider: LocationManager(),
        placeSearch: OpenMeteoGeocodingService()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
