import SwiftUI

@main
struct DarkWeatherApp: App {
    @State private var viewModel = TerminalViewModel(
        weatherService: OpenMeteoWeatherService(),
        locationProvider: LocationManager(),
        placeSearch: OpenMeteoGeocodingService()
    )

    var body: some Scene {
        WindowGroup {
            TerminalView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
