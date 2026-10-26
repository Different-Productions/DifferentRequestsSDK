import DifferentRequestsProtos
import SwiftUI

/// Who wrote a comment, the Team mark where the team did, and how long ago: on one line, and
/// stacked at accessibility text sizes.
struct CommentByline: View {

  let comment: DRComment

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
      VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
        CommentAuthor(comment: comment)
          .textRole(.supporting)
          .fontWeight(.semibold)
          .foregroundStyle(ColorRole.label)
        CommentTeamMark(comment: comment)
        CommentAge(comment: comment)
      }
    } else {
      HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall.rawValue) {
        CommentAuthor(comment: comment)
          .textRole(.supporting)
          .fontWeight(.semibold)
          .foregroundStyle(ColorRole.label)
        CommentTeamMark(comment: comment)
        Spacer(minLength: Spacing.xSmall.rawValue)
        CommentAge(comment: comment)
      }
    }
  }
}
