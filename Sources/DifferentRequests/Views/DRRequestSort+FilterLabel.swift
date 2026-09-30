import DifferentRequestsProtos

/// How a ranking reads in the board's sort menu.
///
/// Prefixed rather than named `label`, so a member the contract adds to the enum later cannot
/// collide with this and silently change what the menu says.
extension DRRequestSort {

  /// Says what the ranking orders by. A ranking with no URL spelling is never offered, but the
  /// switch names it so a new one is a compile error here rather than a blank item.
  var filterLabel: String {
    switch self {
    case .top:
      return String(localized: "Most votes", bundle: .module, comment: "Sort menu item that ranks requests by votes")
    case .new:
      return String(localized: "Newest", bundle: .module, comment: "Sort menu item that ranks requests by date")
    case .unspecified, .UNRECOGNIZED:
      return String(localized: "Unknown", bundle: .module, comment: "A ranking this version has no name for")
    }
  }
}
