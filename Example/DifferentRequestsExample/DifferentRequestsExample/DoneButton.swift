import SwiftUI

/// Closes the sheet an SDK screen was presented in, the same way the board's own Done does.
struct DoneButton: View {

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Button("Done") {
      dismiss()
    }
  }
}
