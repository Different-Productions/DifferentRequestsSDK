import SwiftUI

/// Draws a screen in the look chosen in the dashboard: the tint for the mode being drawn, and the
/// font family.
///
/// A screen is drawn only once the configuration has answered, because the tint, the tabs and the
/// badge all come from it and none of them may be drawn and then replaced. Until then
/// ``ConfigPending`` stands in.
struct WornLook: ViewModifier {

  let hub: DifferentRequestsHub

  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    switch hub.appConfig.badge.state {
    case .none, .reading, .failed:
      ConfigPending(hub: hub)
    case .bought, .carried:
      content
        .tint(hub.tintDrawn(in: colorScheme).tintColor())
        .environment(\.drawnTint, hub.tintDrawn(in: colorScheme))
        .fontDesign(hub.fontDrawn())
    }
  }
}
