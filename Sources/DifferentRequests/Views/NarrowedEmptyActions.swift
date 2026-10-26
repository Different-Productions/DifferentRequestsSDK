import SwiftUI

/// The buttons under an empty Requests screen that a search or a status filter emptied.
///
/// A status filter leaves one more thing to try than a search does, and the likelier one to work,
/// so Show all leads and New request follows it at the same size.
struct NarrowedEmptyActions: View {

  /// What holds the board, and who is signed in.
  let hub: DifferentRequestsHub

  /// Whether the new request form is up.
  @Binding var isComposing: Bool

  var body: some View {
    if hub.board.narrowing.isStatusFiltered {
      VStack(spacing: Spacing.small.rawValue) {
        AsyncButton {
          await hub.board.showEveryStatus()
        } label: {
          Text("Show all", bundle: .module, comment: "Button that clears the status filter on an empty board")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        if hub.whoIsHere.somebodyIsHere {
          NewRequestButton(hub: hub, title: EmptyBoard.standard.button, isComposing: $isComposing)
            .labelStyle(WideTitleLabelStyle())
            .buttonStyle(.bordered)
        }
      }
      .controlSize(.large)
      .fixedSize(horizontal: true, vertical: false)
    } else if hub.whoIsHere.somebodyIsHere {
      NewRequestButton(hub: hub, title: EmptyBoard.standard.button, isComposing: $isComposing)
        .labelStyle(.titleOnly)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
  }
}
