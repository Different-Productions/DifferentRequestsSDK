import SwiftUI

/// The Requests screen's trailing bar buttons on iOS: filter and sort, then New request.
/// ``RequestsBar`` holds the same buttons on macOS.
///
/// The filter button is filled with the tint while a status filter is on. New request is the one
/// filled action, and is offered only to somebody signed in, because asking acts for a person.
struct RequestsToolbar: ToolbarContent {

  /// What holds the board the buttons act on.
  let hub: DifferentRequestsHub

  /// Whether the new request form is up.
  @Binding var requestsScreen: RequestsScreenState

  var body: some ToolbarContent {
    if hub.board.board.statuses.isEmpty {
      ToolbarItem(placement: .primaryAction) {
        FilterMenu(hub: hub)
          .tint(Color.primary)
      }
    } else {
      ToolbarItem(placement: .primaryAction) {
        FilterMenu(hub: hub)
          .menuStyle(.button)
          .buttonStyle(.glassProminent)
          .buttonBorderShape(.circle)
          .controlSize(.large)
          // The style pads its label wider than the circle it draws, so the frame is the circle's.
          .frame(width: TargetSize.minimum.points(), height: TargetSize.minimum.points())
          .contentShape(Rectangle())
          // The bar lays a button out 4 pt inside the circle it draws around it; so is this one.
          .padding(-Spacing.xxSmall.points())
      }
      .sharedBackgroundVisibility(.hidden)
    }

    if hub.whoIsHere.somebodyIsHere() {
      ToolbarSpacer(.fixed, placement: .primaryAction)

      ToolbarItem(placement: .primaryAction) {
        NewRequestButton(
          hub: hub,
          label: NewRequestButtonContent(
            title: String(localized: "New request", bundle: .module, comment: "Button that opens the form for a new feature request")
          ),
          requestsScreen: $requestsScreen
        )
        .labelStyle(.iconOnly)
        .buttonStyle(.glassProminent)
      }
    }
  }
}
