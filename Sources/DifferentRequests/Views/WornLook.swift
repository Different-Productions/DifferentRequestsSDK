import SwiftUI

/// Draws a screen in the look the hub holds: the tint for the mode being drawn, and the host app's
/// font.
///
/// A screen is drawn only once the configuration has answered, because the tint, the tabs and the
/// badge all come from it and none of them may be drawn and then replaced. Until then an untinted
/// spinner stands in; a failed read is a ``LoadFailure`` that reads again.
struct WornLook: ViewModifier {

  let hub: DifferentRequestsHub

  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    switch hub.appConfig.badge {
    case .unread, .reading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
          await hub.appConfig.load()
        }
    case .failed(let error):
      LoadFailure(
        title: String(localized: "Requests couldn't load", bundle: .module, comment: "Heading when the Requests screen failed to load"),
        error: error
      ) {
        await hub.appConfig.load()
      }
    case .bought, .carried:
      content
        .tint(hub.tintDrawn(in: colorScheme))
        .fontDesign(hub.appearanceDrawn.font)
    }
  }
}
