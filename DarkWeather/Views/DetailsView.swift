import SwiftUI

struct DetailsView: View {
    let current: CurrentConditions

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 16) {
            DetailTile(title: "Feels Like", systemImage: "thermometer.medium", value: Format.temperature(current.apparentTemperature))
            DetailTile(title: "Humidity", systemImage: "humidity", value: Format.percent(current.humidity))
            DetailTile(title: "Wind", systemImage: "wind", value: Format.windSpeed(current.windSpeed))
        }
    }
}

private struct DetailTile: View {
    let title: String
    let systemImage: String
    let value: String

    var body: some View {
        Card(title: title, systemImage: systemImage) {
            Text(value)
                .font(.title.weight(.medium))
        }
    }
}

#Preview {
    DetailsView(current: PreviewData.report().current)
        .padding()
        .background(.black)
        .foregroundStyle(.white)
}
