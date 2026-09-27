import DifferentRequestsProtos
import SwiftUI

/// One request an update answers: shipped, its title, and how many asked for it.
struct ChangelogAnswerRow: View {

  private static let spacing: CGFloat = 10

  let answer: DRChangelogAnswer

  var body: some View {
    HStack(spacing: Self.spacing) {
      Image(systemName: "checkmark")
        .fontWeight(.semibold)
        .foregroundStyle(.green)
        .accessibilityHidden(true)

      Text(answer.title)
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)

      Text("\(Int(answer.voteCount)) votes", bundle: .module, comment: "VoiceOver count of a request's votes")
        .font(.footnote)
        .monospacedDigit()
        .foregroundStyle(.secondary)
    }
  }
}
