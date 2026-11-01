import Foundation

/// Lays a forecast out as terminal output, wttr.in style. Columns are built
/// by padding strings, so they only line up in a monospaced font.
enum ForecastPrinter {
    /// Width of section rules; every table row fits inside it.
    static let width = 33

    static func lines(for report: WeatherReport, placeName: String) -> [TerminalLine] {
        var lines: [TerminalLine] = [TerminalLine("# \(placeName.lowercased())", .dim), .blank]
        lines += current(report.current, today: report.daily.first)
        lines += [.blank, header("hourly")]
        for (index, hour) in report.hourly.prefix(12).enumerated() {
            lines.append(hourRow(hour, isFirst: index == 0))
        }
        lines += [.blank, header("\(report.daily.count)-day")]
        let range = temperatureRange(report.daily)
        for (index, day) in report.daily.enumerated() {
            lines.append(dayRow(day, isFirst: index == 0, range: range))
        }
        lines += [.blank, header("details")]
        lines += details(report.current)
        return lines
    }

    /// What VoiceOver reads instead of the ASCII art and tables.
    static func summary(for report: WeatherReport, placeName: String) -> String {
        let current = report.current
        var text = "\(placeName): \(Format.temperature(current.temperature)), \(current.condition.description)."
        if let today = report.daily.first {
            text += " High \(Format.temperature(today.high)), low \(Format.temperature(today.low))."
        }
        return text
    }

    /// `── title ─────────` padded to `width`.
    static func header(_ title: String) -> TerminalLine {
        let lead = "── \(title) "
        let rule = String(repeating: "─", count: max(0, width - lead.count))
        return TerminalLine([.init(text: lead, style: .prompt), .init(text: rule, style: .rule)])
    }

    private static func current(_ current: CurrentConditions, today: DailyForecast?) -> [TerminalLine] {
        let art = current.condition.asciiArt(isDaylight: current.isDaylight)
        var right: [TerminalLine] = [
            TerminalLine(current.condition.description.lowercased(), .dim),
            TerminalLine(Format.temperature(current.temperature)),
        ]
        if let today {
            right.append(TerminalLine([
                .init(text: "↑\(Format.temperature(today.high))", style: .warm),
                .init(text: " ", style: .plain),
                .init(text: "↓\(Format.temperature(today.low))", style: .cool),
            ]))
        }
        var lines: [TerminalLine] = []
        for (index, artLine) in art.enumerated() {
            let left = TerminalLine(artLine + "  ", .warm)
            lines.append(index < right.count ? left + right[index] : left)
        }
        return lines
    }

    private static func hourRow(_ hour: HourlyForecast, isFirst: Bool) -> TerminalLine {
        let time: String = isFirst ? "now" : hour.date.formatted(.dateTime.hour())
        let condition: String = "  " + hour.condition.description.lowercased().rightPadded(to: 14)
        var chance = ""
        if let precipitation = hour.precipitationChance, precipitation >= 0.1 {
            chance = Format.percent(precipitation).leftPadded(to: 4)
        }
        return TerminalLine([
            .init(text: time.rightPadded(to: 7), style: .dim),
            .init(text: Format.temperature(hour.temperature).leftPadded(to: 4), style: .plain),
            .init(text: condition, style: .plain),
            .init(text: chance, style: .cool),
        ])
    }

    private static func dayRow(_ day: DailyForecast, isFirst: Bool, range: ClosedRange<Double>) -> TerminalLine {
        let label: String = isFirst ? "today" : day.date.formatted(.dateTime.weekday(.abbreviated)).lowercased()
        let bar: String = " " + Format.rangeBar(low: day.low, high: day.high, in: range) + " "
        return TerminalLine([
            .init(text: label.rightPadded(to: 6), style: .dim),
            .init(text: day.condition.shortLabel.rightPadded(to: 7), style: .plain),
            .init(text: Format.temperature(day.low).leftPadded(to: 4), style: .cool),
            .init(text: bar, style: .dim),
            .init(text: Format.temperature(day.high).leftPadded(to: 4), style: .warm),
        ])
    }

    private static func details(_ current: CurrentConditions) -> [TerminalLine] {
        [
            detailRow("feels_like", Format.temperature(current.apparentTemperature)),
            detailRow("humidity", Format.percent(current.humidity)),
            detailRow("wind", Format.windSpeed(current.windSpeed)),
        ]
    }

    private static func detailRow(_ key: String, _ value: String) -> TerminalLine {
        TerminalLine([
            .init(text: key.rightPadded(to: 11), style: .dim),
            .init(text: "= ", style: .rule),
            .init(text: value, style: .plain),
        ])
    }

    private static func temperatureRange(_ days: [DailyForecast]) -> ClosedRange<Double> {
        let low: Double = days.map(\.low).min() ?? 0
        let high: Double = days.map(\.high).max() ?? 0
        return low...max(high, low)
    }
}
