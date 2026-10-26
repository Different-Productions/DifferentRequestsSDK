import SwiftUI

/// A 44 by 44 pt close symbol that puts a notice or a card away, spoken as "Dismiss".
struct DismissButton: View {

  /// Puts away whatever this sits on.
  let dismiss: () -> Void

  var body: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: "xmark")
        .textRole(.meta)
        .fontWeight(.semibold)
        .foregroundStyle(ColorRole.label)
        .frame(width: TargetSize.minimum.rawValue, height: TargetSize.minimum.rawValue)
        .contentShape(Rectangle())
    }
    .buttonStyle(.borderless)
    .tint(Color.primary)
    .accessibilityLabel(Text("Dismiss", bundle: .module, comment: "Button that hides a failure notice"))
  }
}
