import SwiftUI

#if canImport(UIKit)
  /// An empty view controller that reports whether the screen it sits in is the root of a
  /// presented navigation stack.
  struct SheetRootProbe: UIViewControllerRepresentable {

    /// Where the answer is written each time the screen appears.
    @Binding var placement: SheetPlacement

    func makeUIViewController(context: Context) -> SheetRootProbeController {
      SheetRootProbeController(placement: $placement)
    }

    func updateUIViewController(_ controller: SheetRootProbeController, context: Context) {
      controller.placement = $placement
    }
  }
#elseif canImport(AppKit)
  /// An empty view that reports whether the screen it sits in is inside a sheet window.
  struct SheetRootProbe: NSViewRepresentable {

    /// Where the answer is written each time the view joins a window.
    @Binding var placement: SheetPlacement

    func makeNSView(context: Context) -> SheetRootProbeView {
      SheetRootProbeView(placement: $placement)
    }

    func updateNSView(_ view: SheetRootProbeView, context: Context) {
      view.placement = $placement
    }
  }
#endif
