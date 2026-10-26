import SwiftUI

/// A request's comments, as rows of a list section: four outcomes from the thread's own read state,
/// so comments that could not be read never look like a request nobody replied to.
struct RequestThread: View {

  /// The request's own store, which holds the thread and reads its pages.
  let store: RequestDetailStore

  var body: some View {
    switch store.thread {
    case .unread, .reading:
      ProgressView()
        .frame(maxWidth: .infinity)
    case .failed:
      RetryRow(
        message: String(
          localized: "Couldn't load the comments.",
          bundle: .module,
          comment: "Row where a request's comments go when they failed to load"
        )
      ) {
        await store.load()
      }
    case .empty:
      Text("No comments yet.", bundle: .module, comment: "Shown under a request with no comments")
        .textRole(.supporting)
        .foregroundStyle(ColorRole.secondaryLabel)
    case .loaded(let comments), .refreshing(let comments):
      ForEach(comments, id: \.id) { comment in
        CommentRow(comment: comment)
      }

      if store.page.isDone == false {
        NextPageRow(
          state: store.page,
          failureMessage: String(
            localized: "Couldn't load more comments.",
            bundle: .module,
            comment: "Row at the end of a request's comments when the next page failed to load"
          )
        ) {
          await store.loadMore()
        }
      }
    }
  }
}
