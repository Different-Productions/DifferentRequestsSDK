import DifferentRequestsProtos
import SwiftUI

/// How long ago a comment was written, in words.
struct CommentAge: View {

  let comment: DRComment

  var body: some View {
    if comment.hasCreatedAt {
      Text(comment.createdAt.ago())
        .textRole(.supporting)
        .foregroundStyle(ColorRole.secondaryLabel)
    }
  }
}
