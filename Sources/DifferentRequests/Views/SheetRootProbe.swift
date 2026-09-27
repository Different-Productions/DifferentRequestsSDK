import SwiftUI

#if canImport(UIKit)
  /// An empty view controller that reports whether the screen it sits in is the root of a
  /// presented navigation stack.
  struct SheetRootProbe: UIViewControllerRepresentable {

    /// Where the answer is written each time the screen appears.
    @Binding var isSheetRoot: Bool

    func makeUIViewController(context: Context) -> SheetRootProbeController {
      SheetRootProbeController(isSheetRoot: $isSheetRoot)
    }

    func updateUIViewController(_ controller: SheetRootProbeController, context: Context) {
      controller.isSheetRoot = $isSheetRoot
    }
  }
#elseif canImport(AppKit)
  /// An empty view that reports whether the screen it sits in is inside a sheet window.
  struct SheetRootProbe: NSViewRepresentable {

    /// Where the answer is written each time the view joins a window.
    @Binding var isSheetRoot: Bool

    func makeNSView(context: Context) -> SheetRootProbeView {
      SheetRootProbeView(isSheetRoot: $isSheetRoot)
    }

    func updateNSView(_ view: SheetRootProbeView, context: Context) {
      view.isSheetRoot = $isSheetRoot
    }
  }
#endif
