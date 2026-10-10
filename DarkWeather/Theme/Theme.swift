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

extension TerminalLine.Style {
    var color: Color {
        switch self {
        case .plain: Theme.text
        case .dim: Theme.dim
        case .prompt: Theme.prompt
        case .warm: Theme.warm
        case .cool: Theme.cool
        case .error: Theme.error
        case .rule: Theme.rule
        }
    }
}

/// Block cursor that blinks unless Reduce Motion is on.
struct BlinkingCursor: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.6)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.6)
            Text(verbatim: "█")
                .foregroundStyle(Theme.prompt)
                .opacity(reduceMotion || tick.isMultiple(of: 2) ? 1 : 0)
        }
        .accessibilityHidden(true)
    }
}
