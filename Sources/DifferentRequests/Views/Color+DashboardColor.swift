import DifferentRequestsProtos
import SwiftUI

extension Color {
  /// The color the contract's three components name, in sRGB.
  ///
  /// Nothing where a component is over the largest a component holds: that is not a color the
  /// dashboard can write, so it is read as none.
  init?(dashboardColor color: DRColor) {
    guard color.isDashboardColor() else {
      return nil
    }
    let largest = ColorComponent.largest.level()
    self.init(
      .sRGB,
      red: Double(color.red) / Double(largest),
      green: Double(color.green) / Double(largest),
      blue: Double(color.blue) / Double(largest)
    )
  }
}
