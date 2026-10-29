import SwiftUI

#if os(macOS)
  /// The Requests screen's buttons on macOS, in a row at the top of the tab: Filter, search, then
  /// New Request….
  ///
  /// New Request… is the one prominent button, offered only to somebody signed in, because asking
  /// acts for a person.
  struct RequestsBar: View {

    /// What holds the board the buttons act on.
    let hub: DifferentRequestsHub

    /// Whether the new request form is pushed.
    @Binding var requestsScreen: RequestsScreenState

    var body: some View {
      HStack(spacing: Spacing.small.points()) {
        FilterMenu(hub: hub)
          .menuStyle(.button)
          .labelStyle(.titleAndIcon)
          // Only New Request… is filled with the tint; Filter stays in the label color.
          .tint(Color.primary)
          .fixedSize()

        BoardSearchField(board: hub.board)

        if hub.whoIsHere.somebodyIsHere() {
          NewRequestButton(
            hub: hub,
            label: NewRequestButtonContent(
              title: String(localized: "New Request…", bundle: .module, comment: "Mac button that opens the form for a new feature request")
            ),
            requestsScreen: $requestsScreen
          )
          .labelStyle(.titleOnly)
          .buttonStyle(.borderedProminent)
          .fixedSize()
        }
      }
      .padding(Spacing.small.points())
    }
  }
#endif
