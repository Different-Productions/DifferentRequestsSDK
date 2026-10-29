import Foundation

/// The sentences live on the narrowing rather than in the view, so a surface cannot assemble them
/// one `if` at a time and drop a branch. A narrowing the SDK cannot name reads as the whole board.
extension BoardNarrowing {

  /// Whether a status filter is part of why the board is empty, and therefore whether dropping it
  /// is one of the things left to try.
  func isStatusFiltered() -> Bool {
    switch self {
    case .statuses, .queryAndStatuses:
      return true
    case .nothing, .query, .unspecified, .UNRECOGNIZED:
      return false
    }
  }

  /// The glyph over an empty board: a tray means nothing has happened here, a magnifier means the
  /// reader asked for something specific.
  func emptyIcon() -> String {
    switch self {
    case .nothing, .unspecified, .UNRECOGNIZED:
      return EmptyBoard().filledIn().symbol
    case .query, .queryAndStatuses:
      return "magnifyingglass"
    case .statuses:
      return "line.3.horizontal.decrease.circle"
    }
  }

  /// The heading over an empty board.
  func emptyTitle() -> String {
    switch self {
    case .nothing, .unspecified, .UNRECOGNIZED:
      return EmptyBoard().filledIn().title
    case .query:
      return String(
        localized: "No requests match your search",
        bundle: .module,
        comment: "Heading over the request board when a search finds nothing"
      )
    case .statuses:
      return String(
        localized: "No requests in this filter",
        bundle: .module,
        comment: "Heading over the request board when the status filter leaves nothing"
      )
    case .queryAndStatuses:
      return String(
        localized: "No requests match in this filter",
        bundle: .module,
        comment: "Heading over the request board when a search inside a status filter finds nothing"
      )
    }
  }

  /// What an empty board says under its heading. The filtered cases name the filter as the reason,
  /// because a reader who narrowed the board three scrolls ago otherwise reads that the app has no
  /// requests at all.
  func emptyMessage() -> String {
    switch self {
    case .nothing, .unspecified, .UNRECOGNIZED:
      return EmptyBoard().filledIn().message
    case .query:
      return String(
        localized: "Nobody has asked for this yet.",
        bundle: .module,
        comment: "Message on the request board when a search finds nothing"
      )
    case .statuses:
      return String(
        localized: "No requests match this filter.",
        bundle: .module,
        comment: "Message on the request board when the status filter leaves nothing; a Show all button sits under it"
      )
    case .queryAndStatuses:
      return String(
        localized: "Nothing matches this search with this filter.",
        bundle: .module,
        comment: "Message on the request board when a search inside a status filter finds nothing; a Show all button sits under it"
      )
    }
  }

  /// What the composer says above the title field, or nil on an unnarrowed board. A status filter
  /// can hide the very request that would have caught a duplicate, so the warning sits where the
  /// duplicate would be written.
  func composerWarning() -> String? {
    switch self {
    case .nothing, .unspecified, .UNRECOGNIZED:
      return nil
    case .query:
      return String(
        localized: "If a request already says this, vote for it instead, so the votes stay in one place.",
        bundle: .module,
        comment: "Warning above the new request form after a search"
      )
    case .statuses, .queryAndStatuses:
      return String(
        localized: "A filter is hiding some requests. Choose All to check that yours isn't already here.",
        bundle: .module,
        comment: "Warning above the new request form while a status filter is on; All is the filter chip's name"
      )
    }
  }
}
