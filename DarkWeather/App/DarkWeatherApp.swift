import SwiftUI

@main
struct DarkWeatherApp: App {
    @State private var viewModel = WeatherViewModel(
        weatherService: OpenMeteoWeatherService(),
        locationProvider: LocationManager()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
