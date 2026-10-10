import SwiftUI

struct ContentView: View {
    let viewModel: WeatherViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()

            switch viewModel.state {
            case .idle, .loading:
                LoadingView()
            case .failed(let message):
                ErrorView(message: message) {
                    Task { await viewModel.refresh() }
                }
            case .loaded(let report):
                ForecastView(report: report, placeName: viewModel.placeName)
                    .refreshable { await viewModel.refresh() }
            }
        }
        .foregroundStyle(Theme.text)
        .font(Theme.mono(.callout))
        .task { await viewModel.refresh() }
    }
}

private struct ForecastView: View {
    let report: WeatherReport
    let placeName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PromptLine(command: "weather \(commandArgument)")
                CurrentConditionsView(current: report.current, today: report.daily.first)
                HourlyForecastView(hours: report.hourly)
                DailyForecastView(days: report.daily)
                DetailsView(current: report.current)
                PromptLine(command: "", showsCursor: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .scrollIndicators(.hidden)
    }

    private var commandArgument: String {
        guard let placeName else { return "--here" }
        return placeName.lowercased().replacingOccurrences(of: " ", with: "-")
    }
}

private struct LoadingView: View {
    private let frames = ["|", "/", "-", "\\"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PromptLine(command: "weather --here")
            TimelineView(.periodic(from: .now, by: 0.12)) { context in
                let frame = Int(context.date.timeIntervalSinceReferenceDate / 0.12) % frames.count
                Text("\(frames[frame]) fetching forecast...")
                    .foregroundStyle(Theme.dim)
            }
        }
        .padding()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading forecast")
    }
}

private struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PromptLine(command: "weather --here")
            Text("error: \(message)")
                .foregroundStyle(Theme.error)
            Button("[ retry ]", action: retry)
                .foregroundStyle(Theme.prompt)
                .padding(.top, 8)
            PromptLine(command: "", showsCursor: true)
        }
        .padding()
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
