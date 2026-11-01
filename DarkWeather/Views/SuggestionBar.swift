import SwiftUI

/// Tappable shortcuts pinned above the keyboard: `[ here ]`, recent cities,
/// or city matches while typing.
struct SuggestionBar: View {
    enum Chip: Hashable {
        case here
        case place(Place)

        var label: String {
            switch self {
            case .here: "here"
            case .place(let place): place.shortName.lowercased()
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .here: "Current location"
            case .place(let place): place.displayName
            }
        }
    }

    let chips: [Chip]
    let select: (Chip) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    Button { select(chip) } label: {
                        HStack(spacing: 0) {
                            Text(verbatim: "[ ").foregroundStyle(Theme.rule)
                            Text(verbatim: chip.label).foregroundStyle(chip == .here ? Theme.prompt : Theme.text)
                            Text(verbatim: " ]").foregroundStyle(Theme.rule)
                        }
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(chip.accessibilityLabel)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }
}

#Preview {
    SuggestionBar(chips: [.here, .place(PreviewData.place)]) { _ in }
        .font(Theme.mono(.callout))
        .preferredColorScheme(.dark)
}
