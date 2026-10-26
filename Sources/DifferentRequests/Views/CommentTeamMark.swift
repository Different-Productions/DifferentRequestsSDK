import DifferentRequestsProtos
import SwiftUI

/// The Team mark for a comment the app's team wrote, and nothing for anyone else's.
struct CommentTeamMark: View {

  let comment: DRComment

  var body: some View {
    switch comment.authorRole {
    case .team:
      TeamMark()
    case .unspecified, .user, .UNRECOGNIZED:
      EmptyView()
    }
  }
}
