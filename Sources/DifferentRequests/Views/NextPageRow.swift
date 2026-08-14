import SwiftUI

/// The row under the last one, and what it does about the page after it.
///
/// A view rather than a bare spinner, because a spinner has only one thing to say and there are
/// three. A spinner left up over a page that failed says "still coming" about a page nothing is
/// waiting for, and it says it for as long as the list is on screen.
///
/// A page that failed therefore stops and offers the retry rather than firing it: a retry that
/// fires itself loops against a server that is down, and each turn of the loop is another request
/// from a device whose network has already said no.
///
/// Draw it only while there is another page — ``PageState/isDone`` — so a fully read list ends
/// on its last row.
struct NextPageRow: View {

  /// Whether there is another page, and what became of the last attempt at one.
  let state: PageState

  /// Asks for it.
  let more: () async -> Void

  var body: some View {
    switch state {
    case .more:
      spinner
        .task {
          await more()
        }
    case .reading:
      spinner
    case .failed:
      RetryRow(message: "Couldn't load any more.") {
        await more()
      }
    case .done:
      EmptyView()
    }
  }

  private var spinner: some View {
    ProgressView()
      .frame(maxWidth: .infinity)
  }
}
