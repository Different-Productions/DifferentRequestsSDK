import DifferentRequestsProtos
import SwiftUI

/// The Requests screen's filter and sort button: one system menu holding the rankings, then All and
/// each status, with a checkmark on what is in effect.
///
/// What it offers is read from the store, which reads the contract's own tables, so nothing here
/// lists a ranking or a status.
struct FilterMenu: View {

  /// What holds the board the menu narrows.
  let hub: DifferentRequestsHub

  var body: some View {
    Menu {
      Section {
        ForEach(hub.board.offeredSorts, id: \.self) { sort in
          AsyncButton {
            await hub.board.show(sort: sort)
          } label: {
            MenuCheckLabel(title: sort.filterLabel, isChecked: hub.board.sort == sort)
          }
        }
      }
      .tint(Color.primary)

      Section {
        AsyncButton {
          await hub.board.showEveryStatus()
        } label: {
          MenuCheckLabel(
            title: String(localized: "All", bundle: .module, comment: "Filter menu item that shows requests in every status"),
            isChecked: hub.board.statuses.isEmpty
          )
        }

        ForEach(hub.board.offeredStatuses, id: \.self) { status in
          AsyncButton {
            await hub.board.toggle(status: status)
          } label: {
            MenuCheckLabel(title: status.localizedLabel, isChecked: hub.board.statuses.contains(status))
          }
        }
      }
      // The checkmarks stay in the label color while the button itself is filled with the tint.
      .tint(Color.primary)
    } label: {
      Label {
        Text("Filter and sort", bundle: .module, comment: "VoiceOver label for the button that opens the filter and sort menu")
      } icon: {
        Image(systemName: "line.3.horizontal.decrease")
      }
    }
  }
}
