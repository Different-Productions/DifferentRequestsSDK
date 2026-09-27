import DifferentRequestsProtos
import SwiftUI

/// One comment in a thread.
///
/// A reply from the tenant's own team is marked as one. An official answer rendered identically
/// to another reader's guess is how a board loses its authority, which is why the contract carries
/// the role at all.
struct CommentRow: View {

  private static let spacing: CGFloat = 4
  private static let headerSpacing: CGFloat = 6
  private static let pillFillOpacity: Double = 0.15

  let comment: DRComment

  var body: some View {
    VStack(alignment: .leading, spacing: Self.spacing) {
      HStack(spacing: Self.headerSpacing) {
        Text(authorName)
          .font(.caption)
          .fontWeight(.semibold)

        if comment.authorRole == .team {
          teamPill
        }

        Spacer()

        if comment.hasCreatedAt {
          Text(comment.createdAt.date.ago)
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }

      commentText
    }
  }

  /// The row stays when a comment is hidden: a thread that silently closes over a removed comment
  /// reads as if the reply was never written.
  @ViewBuilder
  private var commentText: some View {
    switch comment.content {
    case .body(let text):
      Text(text)
        .font(.subheadline)
    case .hidden:
      Text("This comment was removed.", bundle: .module, comment: "Shown in place of a comment the team removed")
        .font(.subheadline)
        .italic()
        .foregroundStyle(.secondary)
    case .none:
      EmptyView()
    }
  }

  private var teamPill: some View {
    Text("Team", bundle: .module, comment: "Pill beside a comment written by the app's team")
      .font(.caption2)
      .fontWeight(.semibold)
      .padding(.horizontal, Self.headerSpacing)
      .padding(.vertical, 1)
      .foregroundStyle(Color.accentColor)
      .background(Color.accentColor.opacity(Self.pillFillOpacity), in: Capsule())
  }

  /// "Deleted user" once the person is deleted, the name their app gave, or "Anonymous" when it
  /// gave none.
  private var authorName: String {
    if comment.authorDeleted {
      return String(localized: "Deleted user", bundle: .module, comment: "Author name for a comment whose person was deleted")
    }
    if comment.hasAuthor, comment.author.displayName.isEmpty == false {
      return comment.author.displayName
    }
    return String(localized: "Anonymous", bundle: .module, comment: "Author name for a comment whose person gave no name")
  }
}
