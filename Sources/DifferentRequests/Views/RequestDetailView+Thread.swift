import SwiftUI

extension RequestDetailView {

  /// Four outcomes again, on the read that is not the request's. A discussion that could not be
  /// read says so and offers to try again; one that is genuinely empty says that instead. Drawn
  /// as one thing they are blank space under a heading that says "Discussion", which reads as a
  /// request nobody has replied to whichever of the two is true.
  @ViewBuilder
  var thread: some View {
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
        .font(.subheadline)
        .foregroundStyle(.secondary)
    case .loaded(let comments), .refreshing(let comments):
      ForEach(comments, id: \.id) { comment in
        CommentRow(comment: comment)
      }

      if store.page.isDone == false {
        NextPageRow(state: store.page) {
          await store.loadMore()
        }
      }
    }
  }
}
