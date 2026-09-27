import DifferentRequestsProtos
import SwiftUI

/// The bar above the board: which statuses it covers, as chips, and how it is ranked, as a menu.
///
/// Above the board's content rather than inside its list, and drawn in every state the board can
/// be in — reading, failed, empty and full — so the control that undoes a narrowing is never taken
/// away by the empty state that narrowing produced.
///
/// What it offers is read from the contract's own tables and filtered to the values that have a
/// spelling in a URL. Nothing here lists a status or a ranking, so one added to the contract
/// arrives by being declared.
struct BoardFilterBar: View {

  private static let chipSpacing: CGFloat = 8
  private static let groupSpacing: CGFloat = 12
  private static let verticalPadding: CGFloat = 8
  private static let menuSpacing: CGFloat = 4

  /// What the bar reads its selection from and writes its taps to. Owned by the hub, so a redraw
  /// above the board cannot reset the filter someone set.
  let store: BoardStore

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: Self.groupSpacing) {
        ChipFlow(spacing: Self.chipSpacing, lineSpacing: Self.chipSpacing) {
          statusChips
        }
        .padding(.leading)

        Spacer(minLength: 0)

        HStack(spacing: Self.chipSpacing) {
          reading
          sortMenu
        }
        .padding(.trailing)
      }
      .padding(.vertical, Self.verticalPadding)

      Divider()
    }
  }

  // MARK: - Ranking

  /// One choice at a time, so a menu naming the current ranking rather than a row of chips.
  private var sortMenu: some View {
    Menu {
      ForEach(store.offeredSorts, id: \.self) { sort in
        AsyncButton {
          await store.show(sort: sort)
        } label: {
          if store.sort == sort {
            Label(sort.filterLabel, systemImage: "checkmark")
          } else {
            Text(sort.filterLabel)
          }
        }
      }
    } label: {
      HStack(spacing: Self.menuSpacing) {
        Text(store.sort.filterLabel)
        Image(systemName: "chevron.down")
          .imageScale(.small)
      }
      .font(.subheadline)
    }
    .fixedSize()
    .accessibilityLabel(Text("Sort", bundle: .module, comment: "VoiceOver label for the board's sort menu"))
    .accessibilityValue(store.sort.filterLabel)
  }

  // MARK: - Statuses

  /// "All" first, because the set being empty is the state a reader wants back and an empty set
  /// draws nothing on its own.
  @ViewBuilder
  private var statusChips: some View {
    FilterChip(
      label: String(localized: "All", bundle: .module, comment: "Filter chip that shows requests in every status"),
      spokenLabel: String(localized: "All statuses", bundle: .module, comment: "VoiceOver label for the All filter chip"),
      isActive: store.statuses.isEmpty
    ) {
      await store.showEveryStatus()
    }

    ForEach(store.offeredStatuses, id: \.self) { status in
      FilterChip(
        label: status.localizedLabel,
        spokenLabel: status.localizedLabel,
        isActive: store.statuses.contains(status)
      ) {
        await store.toggle(status: status)
      }
    }
  }

  // MARK: - In flight

  /// Always in the layout and only sometimes visible, so the bar does not shift width every time a
  /// read starts; hidden from VoiceOver while invisible.
  private var reading: some View {
    ProgressView()
      .controlSize(.small)
      .opacity(store.read.isReading ? 1 : 0)
      .accessibilityHidden(store.read.isReading == false)
  }
}
