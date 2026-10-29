import SwiftUI

/// The buttons under an empty Requests screen that a search or a status filter emptied.
///
/// A status filter leaves one more thing to try than a search does, and the likelier one to work,
/// so Show all leads and New request follows it at the same size.
struct NarrowedEmptyActions: View {

  /// What holds the board, and who is signed in.
  let hub: DifferentRequestsHub

  /// Whether the new request form is up.
  @Binding var requestsScreen: RequestsScreenState

  var body: some View {
    if hub.board.narrowing().isStatusFiltered() {
      VStack(spacing: Spacing.small.points()) {
        AsyncButton {
          await hub.board.showEveryStatus()
        } label: {
          Text("Show all", bundle: .module, comment: "Button that clears the status filter on an empty board")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        if hub.whoIsHere.somebodyIsHere() {
          NewRequestButton(hub: hub, label: newRequestButtonContent(), requestsScreen: $requestsScreen)
            .labelStyle(WideTitleLabelStyle())
            .buttonStyle(.bordered)
        }
      }
      .controlSize(.large)
      .fixedSize(horizontal: true, vertical: false)
    } else if hub.whoIsHere.somebodyIsHere() {
      NewRequestButton(hub: hub, label: newRequestButtonContent(), requestsScreen: $requestsScreen)
        .labelStyle(.titleOnly)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
  }

  /// The button in the SDK's own words: a narrowed board describes what the reader did.
  private func newRequestButtonContent() -> NewRequestButtonContent {
    NewRequestButtonContent(title: EmptyBoard().filledIn().button)
  }
}
