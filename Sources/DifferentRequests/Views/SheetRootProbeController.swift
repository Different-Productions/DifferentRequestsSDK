import SwiftUI

#if canImport(UIKit)
  import UIKit

  /// Finds, each time its screen appears, whether that screen is the first one of a navigation
  /// stack that was presented — a sheet's root, rather than a screen pushed onto any stack.
  final class SheetRootProbeController: UIViewController {

    /// Where the answer is written. Replaced by SwiftUI when the screen is rebuilt.
    var placement: Binding<SheetPlacement>

    init(placement: Binding<SheetPlacement>) {
      self.placement = placement
      super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
      nil
    }

    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      placement.wrappedValue.sheetRoot = isRootOfPresentedStack()
    }

    /// True when the stack holding this screen was presented and this screen is its first.
    private func isRootOfPresentedStack() -> Bool {
      if let navigation = navigationController,
        navigation.presentingViewController != nil,
        let root = navigation.viewControllers.first {
        return sequence(first: self as UIViewController, next: \.parent).contains(root)
      }
      return false
    }
  }
#endif
