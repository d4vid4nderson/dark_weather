import SwiftUI

struct HourlyForecastView: View {
    let hours: [HourlyForecast]

    var body: some View {
        Card(title: "Hourly Forecast", systemImage: "clock") {
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                        VStack(spacing: 8) {
                            Text(index == 0 ? "Now" : hour.date.formatted(.dateTime.hour()))
                                .font(.caption.weight(.semibold))
                            Image(systemName: hour.condition.symbolName())
                                .symbolRenderingMode(.multicolor)
                                .frame(height: 24)
                            Text(hour.precipitationChance.flatMap { $0 >= 0.1 ? Format.percent($0) : nil } ?? " ")
                                .font(.caption2)
                                .foregroundStyle(.cyan)
                            Text(Format.temperature(hour.temperature))
                                .font(.body.weight(.medium))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    HourlyForecastView(hours: PreviewData.report().hourly)
        .padding()
        .background(.black)
        .foregroundStyle(.white)
}
