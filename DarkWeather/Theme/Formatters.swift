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
}
