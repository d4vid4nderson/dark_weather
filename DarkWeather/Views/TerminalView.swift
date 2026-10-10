import SwiftUI

/// The whole app: scrollback, a `$ weather ` prompt, and suggestion chips
/// above the keyboard.
struct TerminalView: View {
    let viewModel: TerminalViewModel

    @State private var input = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "dark weather \(Self.version)")
                    Text(verbatim: "type a city, or tap a suggestion. try 'help'.")
                }
                .foregroundStyle(Theme.dim)

                ForEach(viewModel.entries) { entry in
                    EntryView(entry: entry) { viewModel.markAnimated(entry.id) }
                }

                inputLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            SuggestionBar(chips: chips, select: select)
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.text)
        .font(Theme.mono(.callout))
        .onAppear { isInputFocused = true }
        .task(id: input) {
            // Debounce keystrokes; a newer one cancels this task.
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await viewModel.updateSuggestions(for: input)
        }
    }

    /// `$ weather <input>█`, with a hidden text field doing the typing.
    private var inputLine: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text(verbatim: "$ ").foregroundStyle(Theme.prompt)
                Text(verbatim: "weather \(input)")
                BlinkingCursor()
            }
            .accessibilityHidden(true)

            TextField("", text: $input)
                .focused($isInputFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit(submit)
                .foregroundStyle(.clear)
                .tint(.clear)
                .accessibilityLabel("City")
                .accessibilityHint("Type a city and state, then press Go")
        }
        .contentShape(Rectangle())
        .onTapGesture { isInputFocused = true }
    }

    private var chips: [SuggestionBar.Chip] {
        let isTyping = !input.trimmingCharacters(in: .whitespaces).isEmpty
        if isTyping, !viewModel.suggestions.isEmpty {
            return viewModel.suggestions.map { SuggestionBar.Chip.place($0) }
        }
        let recents: [SuggestionBar.Chip] = viewModel.recents.map { SuggestionBar.Chip.place($0) }
        return [SuggestionBar.Chip.here] + recents
    }

    private func submit() {
        let text = input
        input = ""
        isInputFocused = false
        Task { await viewModel.submit(text) }
    }

    private func select(_ chip: SuggestionBar.Chip) {
        input = ""
        isInputFocused = false
        switch chip {
        case .here: Task { await viewModel.runCurrentLocation() }
        case .place(let place): Task { await viewModel.run(place) }
        }
    }

    private static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
}

/// One command and its output.
private struct EntryView: View {
    let entry: TerminalViewModel.Entry
    let onAnimated: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                Text(verbatim: "$ ").foregroundStyle(Theme.prompt)
                Text(verbatim: entry.command)
            }

            if let lines = entry.lines {
                if let summary = entry.summary {
                    TypewriterView(lines: lines, animate: !entry.hasAnimated, onFinish: onAnimated)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(summary)
                } else {
                    TypewriterView(lines: lines, animate: !entry.hasAnimated, onFinish: onAnimated)
                }
            } else {
                Spinner()
            }
        }
    }
}

/// `| fetching forecast...` with a rotating bar.
private struct Spinner: View {
    private static let frames = ["|", "/", "-", "\\"]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.12)) { context in
            let frame = Int(context.date.timeIntervalSinceReferenceDate / 0.12) % Self.frames.count
            Text(verbatim: "\(Self.frames[frame]) fetching forecast...")
                .foregroundStyle(Theme.dim)
        }
        .accessibilityLabel("Loading forecast")
    }
}

#Preview("Blank") {
    TerminalView(viewModel: TerminalViewModel(
        weatherService: PreviewWeatherService(),
        locationProvider: PreviewLocationProvider(),
        placeSearch: PreviewPlaceSearch(),
        defaults: UserDefaults(suiteName: "preview-blank")!
    ))
    .preferredColorScheme(.dark)
}

#Preview("After a lookup") {
    let viewModel = TerminalViewModel(
        weatherService: PreviewWeatherService(),
        locationProvider: PreviewLocationProvider(),
        placeSearch: PreviewPlaceSearch(),
        defaults: UserDefaults(suiteName: "preview-lookup")!
    )
    return TerminalView(viewModel: viewModel)
        .task { await viewModel.run(PreviewData.place) }
        .preferredColorScheme(.dark)
}
