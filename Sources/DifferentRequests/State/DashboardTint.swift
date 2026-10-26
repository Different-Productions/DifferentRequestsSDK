import DifferentRequestsProtos
import SwiftUI

/// The tint an app's developer chose in the dashboard: one color for light mode and one for dark
/// mode. It wins over the accent the host app passes in code.
///
/// Checked once, where the configuration arrives, so nothing that draws has to ask whether the
/// colors are usable.
struct DashboardTint: Equatable {

  /// Drawn in light mode.
  let light: Color

  /// Drawn in dark mode.
  let dark: Color

  /// The tint a configuration carries, or nothing.
  ///
  /// Nothing where the app's plan leaves its own look out, where no tint was chosen, where either
  /// color is missing, or where a component is not one a color holds.
  init?(config: DRAppConfig) {
    guard
      config.appearanceEnabled,
      config.hasTint,
      config.tint.hasLight,
      config.tint.hasDark,
      let light = Color(dashboardColor: config.tint.light),
      let dark = Color(dashboardColor: config.tint.dark)
    else {
      return nil
    }
    self.light = light
    self.dark = dark
  }

  /// The color for the mode being drawn.
  func color(in colorScheme: ColorScheme) -> Color {
    switch colorScheme {
    case .light:
      return light
    case .dark:
      return dark
    @unknown default:
      return light
    }
  }
}
