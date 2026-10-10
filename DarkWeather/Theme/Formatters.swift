import Foundation

/// Model values are metric; these convert to the user's locale for display.
enum Format {
    private static let temperatureFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .temperatureWithoutUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let speedFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    /// e.g. "72°" in the US, "22°" elsewhere.
    static func temperature(_ celsius: Double) -> String {
        temperatureFormatter.string(from: Measurement(value: celsius, unit: UnitTemperature.celsius))
    }

    static func windSpeed(_ kilometersPerHour: Double) -> String {
        speedFormatter.string(from: Measurement(value: kilometersPerHour, unit: UnitSpeed.kilometersPerHour))
    }

    static func percent(_ fraction: Double) -> String {
        fraction.formatted(.percent.precision(.fractionLength(0)))
    }

    /// Terminal-style age: "just now", "5m ago", "2h ago", "yesterday", "3d ago".
    static func ago(_ date: Date, now: Date = .now) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        switch seconds {
        case ..<60: return "just now"
        case ..<3600: return "\(Int(seconds / 60))m ago"
        case ..<86_400: return "\(Int(seconds / 3600))h ago"
        case ..<172_800: return "yesterday"
        default: return "\(Int(seconds / 86_400))d ago"
        }
    }

    /// Text bar marking where `low...high` falls within `range`, e.g. `░░███████░`.
    static func rangeBar(low: Double, high: Double, in range: ClosedRange<Double>, width: Int = 10) -> String {
        guard width > 0 else { return "" }
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return String(repeating: "█", count: width) }

        func column(_ value: Double) -> Int {
            let position = ((value - range.lowerBound) / span * Double(width - 1)).rounded()
            return min(max(Int(position), 0), width - 1)
        }
        let start = column(low)
        let end = max(column(high), start)
        return String((0..<width).map { (start...end).contains($0) ? "█" : "░" })
    }
}

extension String {
    /// Right-aligns within `width` columns (monospaced layouts).
    func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: " ", count: width - count) + self
    }

    /// Left-aligns within `width` columns (monospaced layouts).
    func rightPadded(to width: Int) -> String {
        count >= width ? self : self + String(repeating: " ", count: width - count)
    }
}
