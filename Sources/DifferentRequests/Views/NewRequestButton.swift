import SwiftUI

/// The way in to the new request form, seeded with whatever the board was searched for.
///
/// The caller picks the label style and the button style: a symbol in the toolbar, words in the
/// middle of an empty screen.
struct NewRequestButton: View {

  /// What holds the form's draft and the search text it starts from.
  let hub: DifferentRequestsHub

  /// What the button says, and is called by VoiceOver.
  let label: NewRequestButtonContent

  /// Whether the form is up.
  @Binding var requestsScreen: RequestsScreenState

  var body: some View {
    Button {
      hub.beginSubmission()
      requestsScreen.composing = true
    } label: {
      Label(label.title, systemImage: "plus")
    }
  }
}
