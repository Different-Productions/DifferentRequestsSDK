import SwiftUI

/// The row under the last one, and what it does about the page after it.
///
/// A page that failed stops and offers the retry, never fires it: a retry that fires itself loops
/// against a server that is down.
///
/// Draw it only while there is another page, ``PageState/isDone``, so a fully read list ends on its
/// last row.
struct NextPageRow: View {

  /// Whether there is another page, and what became of the last attempt at one.
  let state: PageState

  /// What the row says when the next page failed, naming what the list holds.
  let failureMessage: String

  /// Asks for it.
  let more: () async -> Void

  var body: some View {
    switch state {
    case .more:
      ProgressView()
        .frame(maxWidth: .infinity)
        .task {
          await more()
        }
    case .reading:
      ProgressView()
        .frame(maxWidth: .infinity)
    case .failed:
      RetryRow(message: failureMessage) {
        await more()
      }
    case .done:
      EmptyView()
    }
  }
}
