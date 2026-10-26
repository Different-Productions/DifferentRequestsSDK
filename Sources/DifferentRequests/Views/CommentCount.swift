import SwiftUI

/// How many comments a request has: a bubble and the number, spoken as "23 comments".
struct CommentCount: View {

  /// The comments on the request, as the server counts them.
  let count: Int

  var body: some View {
    HStack(spacing: Spacing.xxSmall.rawValue) {
      Image(systemName: "bubble.left")
      Text(count.formatted())
        .monospacedDigit()
    }
    .textRole(.meta)
    .foregroundStyle(ColorRole.secondaryLabel)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("\(count) comments", bundle: .module, comment: "VoiceOver count of a request's comments"))
  }
}
