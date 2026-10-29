import SwiftUI

/// Files the new request and leaves the form once it lands; a spinner while it is sent.
///
/// It is the form's default button, so Return sends.
struct SendSubmissionButton: View {

  /// What the write goes through.
  let hub: DifferentRequestsHub

  /// Whether the question about discarding what was typed is up.
  @Binding var submitScreen: SubmitScreenState

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    if hub.submission.write.isWriting() {
      ProgressView()
    } else if hub.submission.canSubmit() == false {
      // Filled only once it can be tapped: the filled style draws no unavailable look.
      Button {
        submitScreen.confirmingDiscard = false
      } label: {
        Text("Send", bundle: .module, comment: "Button that sends a new request or a comment")
      }
      .disabled(true)
    } else {
      AsyncButton {
        await hub.fileRequest()
        // A refused write leaves the form up with what was typed still in it.
        if hub.submission.draft.hasSubmitted {
          dismiss()
        }
      } label: {
        Text("Send", bundle: .module, comment: "Button that sends a new request or a comment")
      }
      #if os(macOS)
      .buttonStyle(.borderedProminent)
      .keyboardShortcut(.defaultAction)
      #else
      .buttonStyle(.glassProminent)
      #endif
    }
  }
}
