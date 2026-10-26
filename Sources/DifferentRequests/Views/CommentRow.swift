import DifferentRequestsProtos
import SwiftUI

/// One comment in a thread: who wrote it, the Team mark where the team did, and how long ago, on
/// one line; then the text, at the reading size. VoiceOver reads it as one element.
///
/// A removed comment keeps its row, so a thread never closes over a reply as if it was not written.
struct CommentRow: View {

  let comment: DRComment

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
      CommentByline(comment: comment)

      switch comment.content {
      case .body(let text):
        Text(text)
          .textRole(.reading)
          .foregroundStyle(ColorRole.label)
          .textSelection(.enabled)
      case .hidden:
        Text("This comment was removed.", bundle: .module, comment: "Shown in place of a comment the team removed")
          .textRole(.reading)
          .italic()
          .foregroundStyle(ColorRole.secondaryLabel)
      case .none:
        EmptyView()
      }
    }
    .accessibilityElement(children: .combine)
  }
}
