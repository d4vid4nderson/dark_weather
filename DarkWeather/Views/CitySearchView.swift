import SwiftUI

/// `$ weather --city <query>` search, shown when location is denied or the
/// user taps the prompt to change cities.
struct CitySearchView: View {
    let viewModel: WeatherViewModel
    /// Printed as an error line above the prompt, e.g. why GPS isn't available.
    var reason: String?
    /// Called right after the user picks a city or switches back to GPS.
    var onFinish: () -> Void = {}

    @State private var query = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let reason {
                    Text("error: \(reason)")
                        .foregroundStyle(Theme.error)
                }

                HStack(spacing: 0) {
                    Text("$ ").foregroundStyle(Theme.prompt)
                    Text("weather --city ")
                    TextField("", text: $query, prompt: Text("name").foregroundStyle(Theme.dim))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($isFocused)
                        .tint(Theme.prompt)
                        .accessibilityLabel("City name")
                }

                if let error = viewModel.searchError {
                    Text("error: \(error)")
                        .foregroundStyle(Theme.error)
                }

                ForEach(viewModel.searchResults) { place in
                    Button {
                        onFinish()
                        Task { await viewModel.select(place) }
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("> ").foregroundStyle(Theme.prompt)
                            Text(place.displayName.lowercased())
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.selectedPlace != nil {
                    Button("[ use gps ]") {
                        onFinish()
                        Task { await viewModel.useCurrentLocation() }
                    }
                    .foregroundStyle(Theme.prompt)
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.text)
        .font(Theme.mono(.callout))
        .onAppear { isFocused = true }
        .task(id: query) {
            // Debounce keystrokes; a newer query cancels this task.
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await viewModel.search(query)
        }
    }
}

#Preview {
    CitySearchView(
        viewModel: WeatherViewModel(
            weatherService: PreviewWeatherService(),
            locationProvider: PreviewLocationProvider(),
            placeSearch: PreviewPlaceSearch()
        ),
        reason: LocationError.denied.localizedDescription
    )
    .preferredColorScheme(.dark)
}
