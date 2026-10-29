import SwiftUI

#if canImport(AppKit) && !canImport(UIKit)
  import AppKit

  /// Finds, each time it joins a window, whether that window is a sheet.
  ///
  /// macOS gives a SwiftUI screen no view controller stack to read, so a screen pushed inside a
  /// sheet is told it is in a sheet too; the close button there goes back one screen.
  final class SheetRootProbeView: NSView {

    /// Where the answer is written. Replaced by SwiftUI when the screen is rebuilt.
    var placement: Binding<SheetPlacement>

    init(placement: Binding<SheetPlacement>) {
      self.placement = placement
      super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
      nil
    }

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      placement.wrappedValue.sheetRoot = window?.sheetParent != nil
    }
  }
#endif
