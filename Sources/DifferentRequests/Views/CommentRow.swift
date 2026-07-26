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
          Text(comment.createdAt.date.formatted(.relative(presentation: .named)))
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }

      commentText
    }
  }

  /// A hidden comment arrives with its text already dropped, and the row stays: a thread that
  /// silently closes over a removed comment reads as if a reply was never written.
  @ViewBuilder
  private var commentText: some View {
    if comment.isHidden {
      Text("This comment was removed.")
        .font(.subheadline)
        .italic()
        .foregroundStyle(.secondary)
    } else {
      Text(comment.body)
        .font(.subheadline)
    }
  }

  private var teamPill: some View {
    Text("Team")
      .font(.caption2)
      .fontWeight(.semibold)
      .padding(.horizontal, Self.headerSpacing)
      .padding(.vertical, 1)
      .foregroundStyle(Color.accentColor)
      .background(Color.accentColor.opacity(Self.pillFillOpacity), in: Capsule())
  }

  /// The contract says an author is absent for a deleted account and that this is normal, so it
  /// reads as anonymous rather than as a blank line.
  private var authorName: String {
    if comment.hasAuthor, comment.author.displayName.isEmpty == false {
      return comment.author.displayName
    }
    return "Anonymous"
  }
}
