import Foundation

/// One line of terminal output: colored runs of monospaced text.
struct TerminalLine: Equatable, Sendable {
    enum Style: Sendable {
        case plain, dim, prompt, warm, cool, error, rule
    }

    struct Segment: Equatable, Sendable {
        let text: String
        let style: Style
    }

    var segments: [Segment]

    init(_ segments: [Segment]) {
        self.segments = segments
    }

    init(_ text: String, _ style: Style = .plain) {
        self.segments = [Segment(text: text, style: style)]
    }

    static let blank = TerminalLine("")

    /// Characters the typewriter reveals; an empty line still costs one tick.
    var length: Int {
        max(1, segments.reduce(0) { $0 + $1.text.count })
    }

    /// The first `count` characters, keeping each run's style.
    func prefix(_ count: Int) -> TerminalLine {
        var remaining = count
        var kept: [Segment] = []
        for segment in segments where remaining > 0 {
            let text = String(segment.text.prefix(remaining))
            kept.append(Segment(text: text, style: segment.style))
            remaining -= text.count
        }
        return TerminalLine(kept)
    }

    static func + (lhs: TerminalLine, rhs: TerminalLine) -> TerminalLine {
        TerminalLine(lhs.segments + rhs.segments)
    }
}
