import SwiftUI

extension RequestDetailView {

  /// The height the composer occupies, which whatever stands in for it keeps: a strip that grows
  /// and shrinks as the answer arrives moves the thread above it under the reader's eye.
  private static let composerSpacing: CGFloat = 4
  private static let composerPadding: CGFloat = 8

  /// Four outcomes on a question the composer cannot answer for itself: whether this app takes
  /// comments at all.
  ///
  /// A field with a Send that has one possible answer is worse than no field — someone writes a
  /// reply, sends it, and is told by a failure that the discussion was never open. So the slot is
  /// the composer only once the app has said it takes them, and says what is there instead
  /// otherwise. Voting is on the screen above either way, which is what the absent case points at.
  @ViewBuilder
  var composer: some View {
    switch store.commenting {
    case .unread, .reading:
      ProgressView()
        .frame(maxWidth: .infinity)
        .padding(.vertical, Self.composerPadding)
    case .failed:
      RetryRow(
        message: String(
          localized: "Comments didn't load.",
          bundle: .module,
          comment: "Row where the comment field goes when the app's comment setting failed to load"
        )
      ) {
        await store.loadCommenting()
      }
      .padding(.horizontal)
      .padding(.vertical, Self.composerPadding)
    case .excluded:
      commentsOff
    case .included:
      CommentComposer(
        draft: $store.draft,
        canSend: store.canPostComment,
        charactersLeft: store.commentCharactersLeft,
        isWriting: store.write.isWriting
      ) {
        await store.postComment()
      }
    }
  }

  /// The same words `AbsentSurface` gives a whole screen, in the strip the composer would have
  /// had. A screen-sized empty state cannot go here: there is a request above it that is still
  /// worth reading, and it is what the reader came for.
  private var commentsOff: some View {
    VStack(alignment: .leading, spacing: Self.composerSpacing) {
      Label(PlanSurface.comments.absentTitle, systemImage: PlanSurface.comments.absentSymbol)
        .font(.subheadline)

      Text(PlanSurface.comments.absentDescription)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal)
    .padding(.vertical, Self.composerPadding)
  }
}
