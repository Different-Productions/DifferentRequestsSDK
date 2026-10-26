import DifferentRequestsProtos
import SwiftUI

/// Who wrote a comment: "Deleted user" once the person is deleted, the name their app gave, or
/// "Anonymous" when it gave none.
struct CommentAuthor: View {

  let comment: DRComment

  var body: some View {
    if comment.authorDeleted {
      Text("Deleted user", bundle: .module, comment: "Author name for a comment whose person was deleted")
    } else if comment.hasAuthor, comment.author.displayName.isEmpty == false {
      Text(comment.author.displayName)
    } else {
      Text("Anonymous", bundle: .module, comment: "Author name for a comment whose person gave no name")
    }
  }
}
