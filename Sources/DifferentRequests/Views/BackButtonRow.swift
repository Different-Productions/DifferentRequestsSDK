import SwiftUI

/// The Mac's Back: the standard Back symbol in a push button at the leading edge of a row.
struct BackButtonRow: View {

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    HStack {
      Button {
        dismiss()
      } label: {
        Label {
          Text("Back", bundle: .module, comment: "VoiceOver label for the Mac button that returns to the previous screen")
        } icon: {
          Image(systemName: "chevron.backward")
        }
      }
      .labelStyle(.iconOnly)
      .buttonStyle(PillButtonStyle(fill: .gray))
      Spacer()
    }
    .padding(Spacing.small.points())
  }
}
