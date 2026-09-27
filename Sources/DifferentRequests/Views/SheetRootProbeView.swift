#if canImport(AppKit) && !canImport(UIKit)
  import AppKit
  import SwiftUI

  /// Finds, each time it joins a window, whether that window is a sheet.
  ///
  /// macOS gives a SwiftUI screen no view controller stack to read, so a screen pushed inside a
  /// sheet is told it is in a sheet too; Done there goes back one screen.
  final class SheetRootProbeView: NSView {

    /// Where the answer is written. Replaced by SwiftUI when the screen is rebuilt.
    var isSheetRoot: Binding<Bool>

    init(isSheetRoot: Binding<Bool>) {
      self.isSheetRoot = isSheetRoot
      super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
      nil
    }

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      isSheetRoot.wrappedValue = window?.sheetParent != nil
    }
  }
#endif
