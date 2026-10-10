import SwiftUI

/// wttr.in-style block: ASCII art beside the headline numbers.
struct CurrentConditionsView: View {
    let current: CurrentConditions
    let today: DailyForecast?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(current.condition.asciiArt(isDaylight: current.isDaylight).joined(separator: "\n"))
                .foregroundStyle(Theme.warm)
                .fixedSize()
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(current.condition.description.lowercased())
                    .foregroundStyle(Theme.dim)
                Text(Format.temperature(current.temperature))
                    .font(Theme.mono(.largeTitle, weight: .bold))
                if let today {
                    HStack(spacing: 12) {
                        Text("↑\(Format.temperature(today.high))").foregroundStyle(Theme.warm)
                        Text("↓\(Format.temperature(today.low))").foregroundStyle(Theme.cool)
                    }
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let report = PreviewData.report()
    return CurrentConditionsView(current: report.current, today: report.daily.first)
        .padding()
        .background(Theme.background)
        .foregroundStyle(Theme.text)
        .font(Theme.mono(.callout))
}
