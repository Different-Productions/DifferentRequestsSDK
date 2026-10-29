import SwiftUI

/// A Mac sheet's Close: a push button in the sheet's body, which Esc presses.
struct SheetCloseButton: View {

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Button {
      dismiss()
    } label: {
      Text("Close", bundle: .module, comment: "Button that closes the Requests sheet on Mac")
    }
    .keyboardShortcut(.cancelAction)
    // A button that is not the main action stays in the label color.
    .tint(Color.primary)
  }
}
