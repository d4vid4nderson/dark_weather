import SwiftUI

struct DailyForecastView: View {
    let days: [DailyForecast]

    private var range: ClosedRange<Double> {
        let low = days.map(\.low).min() ?? 0
        let high = days.map(\.high).max() ?? 1
        return low...max(high, low + 1)
    }

    var body: some View {
        Card(title: "\(days.count)-Day Forecast", systemImage: "calendar") {
            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    if index > 0 { Divider().overlay(Theme.cardStroke) }
                    HStack(spacing: 12) {
                        Text(index == 0 ? "Today" : day.date.formatted(.dateTime.weekday(.abbreviated)))
                            .frame(width: 52, alignment: .leading)
                        Image(systemName: day.condition.symbolName())
                            .symbolRenderingMode(.multicolor)
                            .frame(width: 28)
                        Text(Format.temperature(day.low))
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 40, alignment: .trailing)
                        TemperatureRangeBar(day: day, range: range)
                        Text(Format.temperature(day.high))
                            .frame(width: 40, alignment: .trailing)
                    }
                    .font(.body.weight(.medium))
                    .padding(.vertical, 10)
                }
            }
        }
    }
}

/// Capsule showing where a day's low/high sits within the whole forecast's range.
private struct TemperatureRangeBar: View {
    let day: DailyForecast
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { proxy in
            let span = range.upperBound - range.lowerBound
            let start = (day.low - range.lowerBound) / span * proxy.size.width
            let width = max((day.high - day.low) / span * proxy.size.width, 4)
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.cardStroke)
                Capsule()
                    .fill(LinearGradient(colors: [.cyan, .yellow, .orange], startPoint: .leading, endPoint: .trailing))
                    .frame(width: width)
                    .offset(x: start)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    DailyForecastView(days: PreviewData.report().daily)
        .padding()
        .background(.black)
        .foregroundStyle(.white)
}
