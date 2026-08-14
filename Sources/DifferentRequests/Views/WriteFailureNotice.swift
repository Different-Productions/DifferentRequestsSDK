import SwiftUI

/// What a surface shows when something the reader did was not written.
///
/// A vote, a follow, a comment, a notification marked read: each of them can be refused, and a
/// refusal a surface does not render is a control that does not move and no explanation of why.
/// This is what every one of them renders it through.
///
/// It sits inside the content rather than over it, next to the control that was tapped, because
/// the control is still there and tapping it again is the whole remedy. The failure itself is
/// never rendered: the contract states an `ApiError`'s message is written for whoever is
/// debugging and may name internals, so the sentence comes from ``WriteAttempt/failureMessage``
/// and the error stays on the store for a developer.
struct WriteFailureNotice: View {

  private static let spacing: CGFloat = 8

  /// Which write failed, and what to say about it.
  let failure: WriteFailure

  /// Puts the notice away. It says nothing about the write, which still did not land.
  let acknowledge: () -> Void

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: Self.spacing) {
      Image(systemName: "exclamationmark.triangle")
        .foregroundStyle(.orange)

      Text(failure.message)
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)

      Button {
        acknowledge()
      } label: {
        Text("Dismiss")
          .font(.subheadline)
      }
      .buttonStyle(.borderless)
    }
    .accessibilityElement(children: .combine)
  }
}
