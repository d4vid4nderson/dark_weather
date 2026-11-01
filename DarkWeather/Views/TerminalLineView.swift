import SwiftUI

/// Renders one line as a single `Text` so it wraps like terminal output.
struct TerminalLineView: View {
    let line: TerminalLine

    var body: some View {
        if line.segments.allSatisfy({ $0.text.isEmpty }) {
            // A space keeps blank lines one row tall.
            Text(verbatim: " ")
        } else {
            line.segments.reduce(Text(verbatim: "")) { (result: Text, segment: TerminalLine.Segment) -> Text in
                result + Text(verbatim: segment.text).foregroundStyle(segment.style.color)
            }
        }
    }
}

/// Prints lines a few characters at a time, like a terminal streaming output.
/// Tap to skip; Reduce Motion shows everything at once.
struct TypewriterView: View {
    let lines: [TerminalLine]
    let onFinish: () -> Void

    @State private var revealed: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let charactersPerTick = 8
    private static let tick: Duration = .milliseconds(12)

    init(lines: [TerminalLine], animate: Bool, onFinish: @escaping () -> Void = {}) {
        self.lines = lines
        self.onFinish = onFinish
        _revealed = State(initialValue: animate ? 0 : lines.reduce(0) { $0 + $1.length })
    }

    private var total: Int { lines.reduce(0) { $0 + $1.length } }

    var body: some View {
        let visible = visibleLines
        VStack(alignment: .leading, spacing: 2) {
            ForEach(visible.indices, id: \.self) { index in
                TerminalLineView(line: visible[index])
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { revealed = total }
        .task {
            guard revealed < total else { return }
            if reduceMotion { revealed = total }
            while revealed < total {
                try? await Task.sleep(for: Self.tick)
                if Task.isCancelled { return }
                revealed = min(total, revealed + Self.charactersPerTick)
            }
            onFinish()
        }
    }

    /// Lines that have started printing, the last one cut to what's revealed.
    private var visibleLines: [TerminalLine] {
        var remaining = revealed
        var result: [TerminalLine] = []
        for line in lines where remaining > 0 {
            result.append(line.prefix(remaining))
            remaining -= line.length
        }
        return result
    }
}
