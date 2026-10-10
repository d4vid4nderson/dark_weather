import SwiftUI

enum Theme {
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.6)
    static let cardBackground = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.08)
    static let cornerRadius: CGFloat = 20

    /// Near-black sky that shifts hue with conditions.
    static func background(for condition: WeatherCondition?, isDaylight: Bool) -> LinearGradient {
        let top: Color
        switch condition {
        case .clear?, .partlyCloudy?:
            top = isDaylight ? Color(red: 0.08, green: 0.14, blue: 0.28) : Color(red: 0.04, green: 0.05, blue: 0.14)
        case .rain?, .drizzle?, .freezingRain?, .thunderstorm?:
            top = Color(red: 0.07, green: 0.09, blue: 0.13)
        case .snow?, .fog?, .cloudy?:
            top = Color(red: 0.11, green: 0.12, blue: 0.15)
        default:
            top = Color(red: 0.06, green: 0.06, blue: 0.08)
        }
        return LinearGradient(colors: [top, .black], startPoint: .top, endPoint: .bottom)
    }
}

/// Rounded translucent panel used for each forecast section.
struct Card<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.cardStroke))
    }
}
