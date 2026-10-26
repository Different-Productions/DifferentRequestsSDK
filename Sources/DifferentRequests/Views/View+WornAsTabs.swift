import SwiftUI

extension View {
  /// ``worn(by:)`` for the tab bar: until the configuration answers, the stand-in can still close
  /// the sheet.
  func wornAsTabs(by hub: DifferentRequestsHub) -> some View {
    modifier(TabsWornLook(hub: hub))
  }
}
