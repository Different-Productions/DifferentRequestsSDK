import SwiftUI

/// ``WornLook`` for the tab bar, which sits in no `NavigationStack` of its own.
///
/// Until the configuration answers, ``ConfigPending`` is drawn inside a stack so the sheet's close
/// button has a toolbar to sit in.
struct TabsWornLook: ViewModifier {

  let hub: DifferentRequestsHub

  func body(content: Content) -> some View {
    switch hub.appConfig.badge {
    case .unread, .reading, .failed:
      NavigationStack {
        ConfigPending(hub: hub)
          .sheetCloseButton()
      }
    case .bought, .carried:
      content
        .worn(by: hub)
    }
  }
}
