import SwiftUI

extension View {
  /// Draws this screen in the host app's own accent and font.
  ///
  /// One place, applied at the top of each screen the SDK ships, so a control added later is worn
  /// by the app without anybody remembering to say so.
  func worn(by appearance: Appearance) -> some View {
    tint(appearance.accent)
      .fontDesign(appearance.font)
  }
}
