import SwiftUI

extension View {
  /// Draws this screen in the look the hub holds: the tint chosen in the dashboard or the host
  /// app's own accent, and the host app's font.
  ///
  /// One place, applied at the top of each screen the SDK ships, so a control added later is worn
  /// by the app without anybody remembering to say so.
  func worn(by hub: DifferentRequestsHub) -> some View {
    modifier(WornLook(hub: hub))
  }
}
