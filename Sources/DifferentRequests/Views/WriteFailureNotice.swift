import SwiftUI

/// What a surface shows when something the reader did was not written: a symbol, the sentence, and
/// a Dismiss button, in a row beside the control that failed. VoiceOver reads it when it appears.
///
/// The failure itself is never rendered: an `ApiError`'s message is written for whoever is
/// debugging, so the sentence comes from ``WriteFailure/message()``.
struct WriteFailureNotice: View {

  /// Which write failed, and what to say about it.
  let failure: WriteFailure

  /// Puts the notice away. It says nothing about the write, which still did not land.
  let acknowledge: () -> Void

  var body: some View {
    HStack(alignment: .center, spacing: Spacing.xSmall.points()) {
      Image(systemName: "exclamationmark.triangle.fill")
        .textRole(.supporting)
        .foregroundStyle(ColorRole.failure)
        .accessibilityHidden(true)

      Text(failure.message())
        .textRole(.supporting)
        .foregroundStyle(ColorRole.label)
        .frame(maxWidth: .infinity, alignment: .leading)

      DismissButton {
        acknowledge()
      }
    }
    .onAppear {
      AccessibilityNotification.Announcement(failure.message()).post()
    }
  }
}
