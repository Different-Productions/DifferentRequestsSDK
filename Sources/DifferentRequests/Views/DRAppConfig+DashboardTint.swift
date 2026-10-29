import DifferentRequestsProtos
import SwiftUI

extension DRAppConfig {

  /// The tint chosen in the dashboard for the mode being drawn.
  ///
  /// Holds no color where the plan leaves the app's own look out, where no tint was chosen, or where
  /// either color is missing or not one a component holds: a tint is both colors or none.
  func dashboardTint(in colorScheme: ColorScheme) -> DrawnTint {
    var drawn = DrawnTint()
    let usable = appearanceEnabled
      && hasTint
      && tint.hasLight
      && tint.hasDark
      && tint.light.isDashboardColor()
      && tint.dark.isDashboardColor()
    if usable {
      switch colorScheme {
      case .light:
        drawn.color = tint.light
      case .dark:
        drawn.color = tint.dark
      @unknown default:
        drawn.color = tint.light
      }
    }
    return drawn
  }
}
