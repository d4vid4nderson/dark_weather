import SwiftUI

struct CurrentConditionsView: View {
    let current: CurrentConditions
    let today: DailyForecast?
    let placeName: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(placeName ?? "Current Location")
                .font(.title2.weight(.medium))
            Text(Format.temperature(current.temperature))
                .font(.system(size: 96, weight: .thin))
            Label(current.condition.description, systemImage: current.condition.symbolName(isDaylight: current.isDaylight))
                .symbolRenderingMode(.multicolor)
                .font(.title3)
                .foregroundStyle(Theme.secondaryText)
            if let today {
                Text("H:\(Format.temperature(today.high))  L:\(Format.temperature(today.low))")
                    .font(.headline)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let report = PreviewData.report()
    return CurrentConditionsView(current: report.current, today: report.daily.first, placeName: "Austin")
        .padding()
        .background(.black)
        .foregroundStyle(.white)
}
