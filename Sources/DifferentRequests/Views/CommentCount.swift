import DifferentRequestsProtos
import SwiftUI

/// How many comments a request has: a bubble and the number, spoken as "23 comments".
struct CommentCount: View {

  /// The request whose comments are counted, as the server counts them.
  let request: DRFeatureRequest

  var body: some View {
    HStack(spacing: Spacing.xxSmall.points()) {
      Image(systemName: "bubble.left")
      Text(request.commentCount.formatted())
        .monospacedDigit()
    }
    .textRole(.meta)
    .foregroundStyle(ColorRole.secondaryLabel)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      Text("\(Int(request.commentCount)) comments", bundle: .module, comment: "VoiceOver count of a request's comments")
    )
  }
}
