import SwiftUI

/// A line inside a list saying a read did not answer, and offering the one thing left to do.
///
/// Sized to sit beside rows rather than to replace a screen, which is what ``LoadFailure`` does.
/// A thread that could not be read still has a request above it worth reading, and a page that
/// could not be read still has every page before it.
///
/// The failure itself is not rendered here either: the contract states an `ApiError`'s message is
/// written for whoever is debugging and may name internals, so the caller passes copy written for
/// a reader and the error stays on the store.
struct RetryRow: View {

  private static let spacing: CGFloat = 4

  /// What could not be read, in words for a reader.
  let message: String

  /// Asks for it again.
  let retry: () async -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: Self.spacing) {
      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      AsyncButton {
        await retry()
      } label: {
        Text("Try Again")
          .font(.subheadline)
      }
      .buttonStyle(.borderless)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
