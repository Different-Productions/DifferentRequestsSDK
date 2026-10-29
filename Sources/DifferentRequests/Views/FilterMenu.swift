import DifferentRequestsProtos
import SwiftUI

/// The Requests screen's filter and sort button: one system menu holding the rankings, then All and
/// each status, with a checkmark on what is in effect.
///
/// What it offers is read from the store, which reads the contract's own tables, so nothing here
/// lists a ranking or a status. On iOS the words beside its symbol are what VoiceOver calls it; on
/// macOS they are drawn.
struct FilterMenu: View {

  /// What holds the board the menu narrows.
  let hub: DifferentRequestsHub

  var body: some View {
    Menu {
      Section {
        ForEach(hub.board.offeredSorts(), id: \.self) { sort in
          AsyncButton {
            await hub.board.show(sort: sort)
          } label: {
            MenuCheckLabel(content: MenuCheckContent(title: sort.filterLabel(), checked: hub.board.board.sort == sort))
          }
        }
      }
      .tint(Color.primary)

      Section {
        AsyncButton {
          await hub.board.showEveryStatus()
        } label: {
          MenuCheckLabel(
            content: MenuCheckContent(
              title: String(localized: "All", bundle: .module, comment: "Filter menu item that shows requests in every status"),
              checked: hub.board.board.statuses.isEmpty
            )
          )
        }

        ForEach(hub.board.offeredStatuses(), id: \.self) { status in
          AsyncButton {
            await hub.board.toggle(status: status)
          } label: {
            MenuCheckLabel(
              content: MenuCheckContent(title: status.localizedLabel(), checked: hub.board.board.statuses.contains(status))
            )
          }
        }
      }
      // The checkmarks stay in the label color while the button itself is filled with the tint.
      .tint(Color.primary)
    } label: {
      Label {
        #if os(macOS)
        Text("Filter", bundle: .module, comment: "Mac button that opens the filter and sort menu")
        #else
        Text("Filter and sort", bundle: .module, comment: "VoiceOver label for the button that opens the filter and sort menu")
        #endif
      } icon: {
        Image(systemName: "line.3.horizontal.decrease")
      }
    }
  }
}
