import SwiftUI

/// The bar at the bottom of a request's screen: the comment field once the app has said it takes
/// comments, and what is there instead until then or otherwise.
///
/// A field whose Send can only be refused is worse than no field, so the field waits for the answer.
struct RequestComposerBar: View {

  /// The request's own store, which holds the draft and whether the app takes comments.
  @Bindable var store: RequestDetailStore

  var body: some View {
    switch store.commenting {
    case .unread, .reading:
      ProgressView()
        .frame(maxWidth: .infinity, minHeight: TargetSize.minimum.rawValue)
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
    case .excluded:
      CommentsOff()
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
}
