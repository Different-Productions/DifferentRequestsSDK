import SwiftUI

/// A row inside a list saying a read did not answer, and offering the one thing left to do. The
/// whole row is the button.
///
/// The failure itself is never rendered: an `ApiError`'s message is written for whoever is
/// debugging, so the caller passes words written for a reader.
struct RetryRow: View {

  /// What could not be read, in words for a reader.
  let message: String

  /// Asks for it again.
  let retry: () async -> Void

  var body: some View {
    AsyncButton {
      await retry()
    } label: {
      VStack(alignment: .leading, spacing: Spacing.xxSmall.rawValue) {
        Text(message)
          .foregroundStyle(ColorRole.secondaryLabel)

        Text("Try again", bundle: .module, comment: "Button that reads something again after it failed")
          .foregroundStyle(ColorRole.tint)
      }
      .textRole(.supporting)
      .frame(maxWidth: .infinity, minHeight: TargetSize.minimum.rawValue, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.borderless)
  }
}
