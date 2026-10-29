import SwiftUI

/// Adds the system close button to a screen only when it is the first screen of a sheet, never when
/// it was pushed.
///
/// SwiftUI's `isPresented` is true for both, so the answer is read from the platform's own view
/// controllers by ``SheetRootProbe``.
///
/// On macOS it is a Close push button in a row at the top of the screen, because a Mac sheet keeps
/// its buttons in its body. Inside ``DifferentRequestsView`` there is none: the sheet draws Close
/// above its tabs.
struct SheetClose: ViewModifier {

  /// Whether this screen is the root of a presented sheet, as the probe last found it.
  @State private var placement = SheetPlacement()

  @Environment(\.dismiss) private var dismiss

  @Environment(\.requestsSheet) private var requestsSheet

  func body(content: Content) -> some View {
    content
      .background {
        SheetRootProbe(placement: $placement)
          .frame(width: 0, height: 0)
          .accessibilityHidden(true)
      }
      #if os(macOS)
      .topRow(SheetCloseRow(content: SheetCloseRowContent(shown: placement.sheetRoot && requestsSheet.inside == false)))
      #else
      .toolbar {
        if placement.sheetRoot {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              dismiss()
            }
            // A bar button that is not the main action stays in the label color.
            .tint(Color.primary)
          }
        }
      }
      #endif
  }
}
