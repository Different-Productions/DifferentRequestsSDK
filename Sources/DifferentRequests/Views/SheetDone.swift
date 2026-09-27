import SwiftUI

/// Adds Done to a screen only when it is the first screen of a sheet, never when it was pushed.
///
/// SwiftUI's `isPresented` is true for both, so the answer is read from the platform's own view
/// controllers by ``SheetRootProbe``.
struct SheetDone: ViewModifier {

  /// Whether this screen is the root of a presented sheet, as the probe last found it.
  @State private var isSheetRoot = false

  @Environment(\.dismiss) private var dismiss

  func body(content: Content) -> some View {
    content
      .background {
        SheetRootProbe(isSheetRoot: $isSheetRoot)
          .frame(width: 0, height: 0)
          .accessibilityHidden(true)
      }
      .toolbar {
        if isSheetRoot {
          ToolbarItem(placement: .cancellationAction) {
            Button {
              dismiss()
            } label: {
              Text("Done", bundle: .module, comment: "Button that closes the request board")
            }
          }
        }
      }
  }
}
