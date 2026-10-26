import DifferentRequestsProtos
import SwiftUI

/// One request an update answers, as its own row that opens the request: the shipped mark and the
/// request's title.
struct ChangelogAnswerRow: View {

  /// What a push from this row is built against.
  let hub: DifferentRequestsHub

  let answer: DRChangelogAnswer

  var body: some View {
    NavigationLink {
      RequestDetailView(hub: hub, requestID: answer.requestID)
    } label: {
      HStack(alignment: .firstTextBaseline, spacing: Spacing.small.rawValue) {
        Image(systemName: "checkmark.circle.fill")
          .accessibilityHidden(true)
        Text(answer.title)
      }
      .textRole(.reading)
      .foregroundStyle(ColorRole.label)
    }
  }
}
