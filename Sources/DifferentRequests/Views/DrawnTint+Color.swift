import SwiftUI

extension DrawnTint {

  /// The color drawn: the dashboard's, or the system's accent color where none was chosen.
  func tintColor() -> Color {
    if hasColor, let chosen = Color(dashboardColor: color) {
      return chosen
    }
    return Color.accentColor
  }
}
