import DifferentRequestsProtos
import SwiftUI

/// The bar above the board: how it is ranked, and which statuses it covers.
///
/// Above the board's content rather than inside its list, and drawn in every state the board can
/// be in — reading, failed, empty and full. A filter that lives inside the list is a filter that
/// disappears at the one moment it has to be reachable: narrow to a status nothing is in and the
/// list is replaced by an empty state, taking with it the only control that could undo the
/// narrowing. What is left says the app has no feature requests, which is not true and cannot be
/// argued with.
///
/// What it offers is read from the contract's own tables and filtered to the values that have a
/// spelling in a URL. A value with no spelling cannot be sent, so it is not offered; that is what
/// keeps `unspecified` — the zero every proto enum decodes to by default — off the bar and out of
/// the query string. Nothing here lists a status or a ranking, so one added to the contract
/// arrives by being declared.
struct BoardFilterBar: View {

  private static let chipSpacing: CGFloat = 8
  private static let groupSpacing: CGFloat = 12
  private static let verticalPadding: CGFloat = 8
  private static let dividerHeight: CGFloat = 20

  /// What the bar reads its selection from and writes its taps to. Owned by the hub, so a redraw
  /// above the board cannot reset the filter someone set.
  let store: BoardStore

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: Self.groupSpacing) {
        ScrollView(.horizontal) {
          HStack(spacing: Self.chipSpacing) {
            sortChips
            Divider()
              .frame(height: Self.dividerHeight)
            statusChips
          }
          .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        // Sized to its capsules vertically rather than left flexible. A `ScrollView` stacked above
        // the board's list is a second greedy child, and two greedy children split the screen
        // between them — which would draw a strip of chips down half of it.
        .fixedSize(horizontal: false, vertical: true)

        reading
          .padding(.trailing)
      }
      .padding(.vertical, Self.verticalPadding)

      Divider()
    }
  }

  // MARK: - Ranking

  private var sortChips: some View {
    ForEach(store.offeredSorts, id: \.self) { sort in
      FilterChip(
        label: sort.filterLabel,
        spokenLabel: sort.filterSpokenLabel,
        isActive: store.sort == sort
      ) {
        await store.show(sort: sort)
      }
    }
  }

  // MARK: - Statuses

  /// "All" first, because the set being empty is the state a reader wants back and an empty set
  /// draws nothing on its own.
  @ViewBuilder
  private var statusChips: some View {
    FilterChip(
      label: "All",
      spokenLabel: "Show every status",
      isActive: store.statuses.isEmpty
    ) {
      await store.showEveryStatus()
    }

    ForEach(store.offeredStatuses, id: \.self) { status in
      FilterChip(
        label: status.badgeLabel,
        spokenLabel: status.badgeLabel,
        isActive: store.statuses.contains(status)
      ) {
        await store.toggle(status: status)
      }
    }
  }

  // MARK: - In flight

  /// A tap on a chip keeps the rows already on screen up — `refreshing` holds them there on
  /// purpose, so a filter change does not blank the list underneath it — which leaves the tapped
  /// chip's own highlight as the only sign anything happened. This says the board is being fetched
  /// as well as chosen.
  ///
  /// Always in the layout and only sometimes visible, so the strip beside it does not shift width
  /// every time a read starts. Hidden from VoiceOver when invisible, or every board would announce
  /// a busy indicator that is not there.
  private var reading: some View {
    ProgressView()
      .controlSize(.small)
      .opacity(store.read.isReading ? 1 : 0)
      .accessibilityHidden(store.read.isReading == false)
  }
}

// MARK: - Presentation

/// How a ranking reads on this bar.
///
/// Prefixed rather than named `label`, so a member the contract adds to the enum later cannot
/// collide with one of these and silently change what a chip says.
extension DRRequestSort {

  /// One word, because it sits in a row of them. A ranking this SDK version has no word for is
  /// never drawn — the bar offers only what has a URL spelling — but the switch names it anyway,
  /// so adding a ranking to the contract is a compile error here rather than a blank chip.
  var filterLabel: String {
    switch self {
    case .top: return "Top"
    case .new: return "New"
    case .unspecified, .UNRECOGNIZED: return "Unknown"
    }
  }

  /// The same thing said in full. "Top" and "New" are a ranking when they are read beside each
  /// other and a guess when they are read one at a time, which is how VoiceOver reads them.
  var filterSpokenLabel: String {
    switch self {
    case .top: return "Rank by most votes"
    case .new: return "Rank by newest"
    case .unspecified, .UNRECOGNIZED: return "Unknown ranking"
    }
  }
}
