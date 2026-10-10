import SwiftUI

/// `key = value` readout of the remaining current conditions.
struct DetailsView: View {
    let current: CurrentConditions

    var body: some View {
        TerminalSection(title: "details") {
            VStack(alignment: .leading, spacing: 2) {
                row("feels_like", Format.temperature(current.apparentTemperature))
                row("humidity", Format.percent(current.humidity))
                row("wind", Format.windSpeed(current.windSpeed))
            }
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack(spacing: 0) {
            Text(key.rightPadded(to: 11)).foregroundStyle(Theme.dim)
            Text("= ").foregroundStyle(Theme.rule)
            Text(value)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

#Preview {
    DetailsView(current: PreviewData.report().current)
        .padding()
        .background(Theme.background)
        .foregroundStyle(Theme.text)
        .font(Theme.mono(.callout))
}
