import SwiftUI

/// The whole app: scrollback, `▸ recent` and a `$ weather ` prompt, and
/// suggestion chips above the keyboard.
struct TerminalView: View {
    let viewModel: TerminalViewModel

    @State private var input = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "\(AppInfo.name) \(AppInfo.version)")
                    Text(verbatim: "type a city, state. try 'help'.")
                }
                .foregroundStyle(Theme.dim)

                ForEach(viewModel.entries) { entry in
                    EntryView(
                        entry: entry,
                        onAnimated: { viewModel.markAnimated(entry.id) },
                        select: { place in run { await viewModel.run(place) } },
                        clearScreen: { viewModel.clearScreen() },
                        forgetAll: { viewModel.forgetAll() }
                    )
                }

                VStack(alignment: .leading, spacing: 0) {
                    if !viewModel.recents.isEmpty {
                        recentButton
                    }
                    inputLine
                }
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

    /// `▸ recent (3)`: lists recent cities when tapped.
    private var recentButton: some View {
        Button {
            run { viewModel.showRecents() }
        } label: {
            HStack(spacing: 0) {
                Text(verbatim: "▸ ").foregroundStyle(Theme.prompt)
                Text(verbatim: "recent ")
                Text(verbatim: "(\(viewModel.recents.count))").foregroundStyle(Theme.dim)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Recent cities, \(viewModel.recents.count)")
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

    /// City matches while typing; otherwise just `[ here ]`.
    private var chips: [SuggestionBar.Chip] {
        let isTyping = !input.trimmingCharacters(in: .whitespaces).isEmpty
        if isTyping, !viewModel.suggestions.isEmpty {
            return viewModel.suggestions.map { SuggestionBar.Chip.place($0) }
        }
        return [SuggestionBar.Chip.here]
    }

    private func submit() {
        let text = input
        run { await viewModel.submit(text) }
    }

    private func select(_ chip: SuggestionBar.Chip) {
        switch chip {
        case .here: run { await viewModel.runCurrentLocation() }
        case .place(let place): run { await viewModel.run(place) }
        }
    }

    /// Clears the prompt and hides the keyboard so the output has room.
    private func run(_ action: @escaping @MainActor () async -> Void) {
        input = ""
        isInputFocused = false
        Task { await action() }
    }
}

/// One command and its output.
private struct EntryView: View {
    let entry: TerminalViewModel.Entry
    let onAnimated: () -> Void
    let select: (Place) -> Void
    let clearScreen: () -> Void
    let forgetAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                Text(verbatim: "$ ").foregroundStyle(Theme.prompt)
                Text(verbatim: entry.command)
            }

            switch entry.content {
            case .running:
                Spinner()
            case .lines(let lines, let summary?):
                TypewriterView(lines: lines, animate: !entry.hasAnimated, onFinish: onAnimated)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(summary)
            case .lines(let lines, nil):
                TypewriterView(lines: lines, animate: !entry.hasAnimated, onFinish: onAnimated)
            case .recents(let recents):
                RecentListView(recents: recents, select: select, clearScreen: clearScreen, forgetAll: forgetAll)
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
