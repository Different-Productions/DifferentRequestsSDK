import SwiftUI

/// What a surface shows in place of content it could not read.
///
/// The failure's own message is never rendered. The contract states that an `ApiError`'s message
/// is written for whoever is debugging, may name internals, and must not be shown to an end user —
/// so the sentence here comes from ``ReadTrouble``, which reads only the failure's kind.
struct LoadFailure: View {

  /// What the read threw, which picks the sentence.
  private let error: any Error

  /// What "Try again" does.
  private let retry: () async -> Void

  init(error: any Error, retry: @escaping () async -> Void) {
    self.error = error
    self.retry = retry
  }

  var body: some View {
    ContentUnavailableView {
      Label {
        Text("Couldn't load", bundle: .module, comment: "Heading on a screen that failed to load")
      } icon: {
        Image(systemName: "exclamationmark.triangle")
      }
    } description: {
      Text(ReadTrouble(error: error).message)
    } actions: {
      AsyncButton {
        await retry()
      } label: {
        Text("Try again", bundle: .module, comment: "Button that reads something again after it failed")
          .foregroundStyle(.background)
          .frame(maxWidth: CallToActionSize.width)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
    }
  }
}
