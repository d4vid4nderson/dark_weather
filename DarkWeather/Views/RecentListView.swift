import SwiftUI

/// Output of `weather --recent`: numbered, tappable cities plus
/// `[ clear screen ]` and `[ forget all ]`.
struct RecentListView: View {
    let recents: [TerminalViewModel.RecentPlace]
    let select: (Place) -> Void
    let clearScreen: () -> Void
    let forgetAll: () -> Void

    @State private var isConfirmingForget = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(recents.enumerated()), id: \.element.id) { index, recent in
                Button { select(recent.place) } label: {
                    row(number: index + 1, recent: recent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(recent.place.displayName), checked \(Format.ago(recent.lastChecked))")
            }

            HStack(spacing: 24) {
                Button { clearScreen() } label: { bracketed("clear screen", color: Theme.prompt) }
                Button { isConfirmingForget = true } label: { bracketed("forget all", color: Theme.error) }
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)
        }
        .confirmationDialog("Forget all recent cities?", isPresented: $isConfirmingForget, titleVisibility: .visible) {
            Button("Forget All", role: .destructive, action: forgetAll)
        }
    }

    private func row(number: Int, recent: TerminalViewModel.RecentPlace) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: "  \(number)  ").foregroundStyle(Theme.dim)
            Text(verbatim: recent.place.shortName.lowercased().rightPadded(to: 16) + " ")
            Text(verbatim: Format.ago(recent.lastChecked)).foregroundStyle(Theme.dim)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private func bracketed(_ label: String, color: Color) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: "[ ").foregroundStyle(Theme.rule)
            Text(verbatim: label).foregroundStyle(color)
            Text(verbatim: " ]").foregroundStyle(Theme.rule)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}
