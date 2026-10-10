import SwiftUI

/// Dark-gray terminal palette. Everything is monospaced so columns line up.
enum Theme {
    static let background = Color(white: 0.11)
    static let text = Color(white: 0.86)
    static let dim = Color(white: 0.5)
    static let rule = Color(white: 0.25)
    static let prompt = Color(red: 0.47, green: 0.86, blue: 0.52)
    static let warm = Color(red: 0.96, green: 0.76, blue: 0.36)
    static let cool = Color(red: 0.47, green: 0.78, blue: 0.96)
    static let error = Color(red: 0.96, green: 0.42, blue: 0.40)

    static func mono(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }
}

/// `── title ─────────` header followed by the section's output.
struct TerminalSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("── \(title)")
                    .foregroundStyle(Theme.prompt)
                Rectangle()
                    .fill(Theme.rule)
                    .frame(height: 1)
            }
            .font(Theme.mono(.footnote, weight: .semibold))
            .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

/// Block cursor that blinks unless Reduce Motion is on.
struct BlinkingCursor: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.6)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.6)
            Text("█")
                .foregroundStyle(Theme.prompt)
                .opacity(reduceMotion || tick.isMultiple(of: 2) ? 1 : 0)
        }
        .accessibilityHidden(true)
    }
}

/// `$ command` line.
struct PromptLine: View {
    let command: String
    var showsCursor = false

    var body: some View {
        HStack(spacing: 0) {
            Text("$ ").foregroundStyle(Theme.prompt)
            Text(command)
            if showsCursor { BlinkingCursor() }
        }
        .font(Theme.mono(.callout))
    }
}
