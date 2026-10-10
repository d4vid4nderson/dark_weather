import SwiftUI

struct ContentView: View {
    let viewModel: WeatherViewModel

    var body: some View {
        ZStack {
            Theme.background(for: report?.current.condition, isDaylight: report?.current.isDaylight ?? false)
                .ignoresSafeArea()

            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .tint(Theme.primaryText)
            case .failed(let message):
                ErrorView(message: message) {
                    Task { await viewModel.refresh() }
                }
            case .loaded(let report):
                ForecastView(report: report, placeName: viewModel.placeName)
                    .refreshable { await viewModel.refresh() }
            }
        }
        .foregroundStyle(Theme.primaryText)
        .task { await viewModel.refresh() }
    }

    private var report: WeatherReport? {
        if case .loaded(let report) = viewModel.state { report } else { nil }
    }
}

private struct ForecastView: View {
    let report: WeatherReport
    let placeName: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CurrentConditionsView(current: report.current, today: report.daily.first, placeName: placeName)
                    .padding(.vertical, 32)
                HourlyForecastView(hours: report.hourly)
                DailyForecastView(days: report.daily)
                DetailsView(current: report.current)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}

private struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Forecast", systemImage: "cloud.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.bordered)
        }
    }
}

#Preview("Loaded") {
    ContentView(viewModel: WeatherViewModel(
        weatherService: PreviewWeatherService(),
        locationProvider: PreviewLocationProvider()
    ))
    .preferredColorScheme(.dark)
}

#Preview("Location denied") {
    ContentView(viewModel: WeatherViewModel(
        weatherService: PreviewWeatherService(),
        locationProvider: PreviewLocationProvider(result: .failure(LocationError.denied))
    ))
    .preferredColorScheme(.dark)
}
