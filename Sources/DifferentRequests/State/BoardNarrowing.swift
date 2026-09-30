import DifferentRequestsProtos
import Foundation

/// What is keeping requests off the board, which is the whole of what an empty board means.
///
/// A board with nothing on it is four different situations wearing the same blank page, and only
/// one of them is "this app has no feature board". Told apart, each has something to offer: the
/// first has nobody to blame and an invitation to be first, the second has words that can be
/// changed, and the two with a status filter on them have requests sitting just out of sight behind
/// a control the reader set themselves and may no longer remember setting.
///
/// The sentences live here rather than in the view for the same reason ``WriteAttempt`` carries
/// its own: a surface that assembles this copy one `if` at a time is free to drop a branch and
/// still compile, and the branch that goes is always the one nobody was looking at.
enum BoardNarrowing: CaseIterable {

  /// The whole board, unsearched. Nothing is being held back.
  case nothing

  /// Narrowed by what was typed into the search field.
  case query

  /// Narrowed to a set of statuses.
  case statuses

  /// Narrowed by both, which is the one case where a duplicate can be hidden from the person about
  /// to file it.
  case queryAndStatuses

  /// What a question is holding back, read off the contract's own request.
  init(question: DRListRequestsRequest) {
    switch (question.query.isEmpty, question.statuses.isEmpty) {
    case (true, true):
      self = .nothing
    case (false, true):
      self = .query
    case (true, false):
      self = .statuses
    case (false, false):
      self = .queryAndStatuses
    }
  }

  /// Whether a status filter is part of why the board is empty, and therefore whether dropping it
  /// is one of the things left to try.
  var isStatusFiltered: Bool {
    switch self {
    case .statuses, .queryAndStatuses:
      return true
    case .nothing, .query:
      return false
    }
  }

  /// The glyph over an empty board. Different per case, because the picture is the first thing read
  /// and a tray means "nothing has happened here" while a magnifier means "you asked for something
  /// specific".
  var emptyIcon: String {
    switch self {
    case .nothing:
      return EmptyBoard.standard.symbol
    case .query, .queryAndStatuses:
      return "magnifyingglass"
    case .statuses:
      return "line.3.horizontal.decrease.circle"
    }
  }

  /// The heading over an empty board.
  var emptyTitle: String {
    switch self {
    case .nothing:
      return EmptyBoard.standard.title
    case .query:
      return String(localized: "Nothing matches", bundle: .module, comment: "Heading over the request board when a search finds nothing")
    case .statuses:
      return String(
        localized: "Nothing in this filter",
        bundle: .module,
        comment: "Heading over the request board when the status filter leaves nothing"
      )
    case .queryAndStatuses:
      return String(
        localized: "No matches in this filter",
        bundle: .module,
        comment: "Heading over the request board when a search inside a status filter finds nothing"
      )
    }
  }

  /// What an empty board says under its heading. The two filtered cases name the filter as the
  /// reason and point at the control that undoes it, because a reader who narrowed the board three
  /// scrolls ago is looking at a page that says the app has no requests at all.
  var emptyMessage: String {
    switch self {
    case .nothing:
      return EmptyBoard.standard.message
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

  /// What the composer says above the title field, when the board behind it was narrowed.
  ///
  /// Nil on an unnarrowed board, where there is nothing to warn about. A status filter can hide
  /// the very request that would have caught a duplicate — it is on the board, it is just
  /// `shipped` and the reader is looking at `open` — so the warning belongs at the moment the
  /// duplicate would be written rather than on the list it is missing from.
  var composerWarning: String? {
    switch self {
    case .nothing:
      return nil
    case .query:
      return String(
        localized: "If a request already says this, vote for it instead, so the votes stay in one place.",
        bundle: .module,
        comment: "Warning above the new request form after a search"
      )
    case .statuses, .queryAndStatuses:
      return String(
        localized: "You're only seeing some requests. Tap All first, so you don't ask for something that's already here.",
        bundle: .module,
        comment: "Warning above the new request form while a status filter is on; All is the filter chip's name"
      )
    }
  }
}
