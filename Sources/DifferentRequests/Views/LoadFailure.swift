import SwiftUI

/// What a surface shows in place of content it could not read.
///
/// The failure's own message is never rendered: an `ApiError`'s message is written for whoever is
/// debugging and must not be shown to an end user, so the sentence comes from ``ReadTrouble``,
/// which reads only the failure's kind.
struct LoadFailure: View {

  /// The heading, naming the screen that could not be read.
  let title: String

  /// What the read threw, which picks the sentence.
  let error: any Error

  /// What "Try again" does.
  let retry: () async -> Void

  var body: some View {
    ContentUnavailableView {
      Label {
        Text(title)
      } icon: {
        ReadTroubleSymbol(trouble: ReadTrouble(error: error))
      }
    } description: {
      Text(ReadTrouble(error: error).message)
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
