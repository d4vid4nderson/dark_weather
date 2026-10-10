import SwiftUI

/// Next 12 hours as a text table: time, temp, condition, chance of rain.
struct HourlyForecastView: View {
    let hours: [HourlyForecast]

    var body: some View {
        TerminalSection(title: "hourly") {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(hours.prefix(12).enumerated()), id: \.element.id) { index, hour in
                    HStack(spacing: 0) {
                        Text(timeLabel(hour, isFirst: index == 0))
                            .foregroundStyle(Theme.dim)
                        Text(Format.temperature(hour.temperature).leftPadded(to: 4))
                        Text("  " + hour.condition.description.lowercased().rightPadded(to: 14))
                        Text(precipitation(hour).leftPadded(to: 4))
                            .foregroundStyle(Theme.cool)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                }
            }
        }
    }

    private func timeLabel(_ hour: HourlyForecast, isFirst: Bool) -> String {
        let label: String = isFirst ? "now" : hour.date.formatted(.dateTime.hour())
        return label.rightPadded(to: 7)
    }

    private func precipitation(_ hour: HourlyForecast) -> String {
        guard let chance = hour.precipitationChance, chance >= 0.1 else { return "" }
        return Format.percent(chance)
    }
}

#Preview {
    HourlyForecastView(hours: PreviewData.report().hourly)
        .padding()
        .background(Theme.background)
        .foregroundStyle(Theme.text)
        .font(Theme.mono(.callout))
}
