import SwiftUI

extension View {

  /// A floor for a full SDK screen's size on macOS, where a sheet sizes itself to its content and
  /// a `List` has no height of its own. Nothing on iOS, where a sheet fills its space.
  func sheetMinimumSize() -> some View {
    #if os(macOS)
      frame(minWidth: SheetMinimumSize.width, minHeight: SheetMinimumSize.height)
    #else
      self
    #endif
  }
}
