import SwiftUI

/// One row per day: weekday, condition, low, range bar, high.
struct DailyForecastView: View {
    let days: [DailyForecast]

    private var range: ClosedRange<Double> {
        let low = days.map(\.low).min() ?? 0
        let high = days.map(\.high).max() ?? 0
        return low...max(high, low)
    }

    var body: some View {
        TerminalSection(title: "\(days.count)-day") {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    HStack(spacing: 0) {
                        Text(dayLabel(day, isFirst: index == 0))
                            .foregroundStyle(Theme.dim)
                        Text(day.condition.shortLabel.rightPadded(to: 7))
                        Text(Format.temperature(day.low).leftPadded(to: 4))
                            .foregroundStyle(Theme.cool)
                        Text(bar(day))
                            .foregroundStyle(Theme.dim)
                            .accessibilityHidden(true)
                        Text(Format.temperature(day.high).leftPadded(to: 4))
                            .foregroundStyle(Theme.warm)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                }
            }
        }
    }

    private func dayLabel(_ day: DailyForecast, isFirst: Bool) -> String {
        let label: String = isFirst ? "today" : day.date.formatted(.dateTime.weekday(.abbreviated)).lowercased()
        return label.rightPadded(to: 6)
    }

    private func bar(_ day: DailyForecast) -> String {
        " \(Format.rangeBar(low: day.low, high: day.high, in: range)) "
    }
}

#Preview {
    DailyForecastView(days: PreviewData.report().daily)
        .padding()
        .background(Theme.background)
        .foregroundStyle(Theme.text)
        .font(Theme.mono(.callout))
}
