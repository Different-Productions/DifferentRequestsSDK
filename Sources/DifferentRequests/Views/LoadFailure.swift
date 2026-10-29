import SwiftUI

/// What a surface shows in place of content it could not read.
///
/// The failure's own message is never rendered: an `ApiError`'s message is written for whoever is
/// debugging and must not be shown to an end user, so the sentence comes from ``ReadTrouble``,
/// which reads only the failure's kind.
struct LoadFailure: View {

  /// The heading naming the screen that could not be read, and why the read did not answer.
  let content: LoadFailureContent

  /// What "Try again" does.
  let retry: () async -> Void

  var body: some View {
    ContentUnavailableView {
      Label {
        Text(content.title)
      } icon: {
        ReadTroubleSymbol(trouble: content.trouble)
      }
    } description: {
      Text(content.trouble.message())
    } actions: {
      AsyncButton {
        await retry()
      } label: {
        Text("Try again", bundle: .module, comment: "Button that reads something again after it failed")
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
    }
  }
}
