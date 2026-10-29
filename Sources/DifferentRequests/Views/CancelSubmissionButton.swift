import SwiftUI

/// Leaves the new request form, asking first when something has been typed.
struct CancelSubmissionButton: View {

  /// What holds the draft.
  let hub: DifferentRequestsHub

  /// Whether the question about discarding what was typed is up.
  @Binding var submitScreen: SubmitScreenState

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Button {
      if hub.submission.holdsDraft() {
        submitScreen.confirmingDiscard = true
      } else {
        dismiss()
      }
    } label: {
      Text("Cancel", bundle: .module, comment: "Button that closes the new request form without sending")
    }
    .tint(Color.primary)
  }
}
