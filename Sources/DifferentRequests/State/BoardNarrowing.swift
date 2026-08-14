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
}

extension BoardNarrowing {

  /// What a question is holding back, read off the question itself.
  init(question: BoardQuestion) {
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
      return "tray"
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
      return "No requests yet"
    case .query:
      return "Nothing matches"
    case .statuses:
      return "Nothing in this filter"
    case .queryAndStatuses:
      return "No matches in this filter"
    }
  }

  /// What an empty board says under its heading. The two filtered cases name the filter as the
  /// reason and point at the control that undoes it, because a reader who narrowed the board three
  /// scrolls ago is looking at a page that says the app has no requests at all.
  var emptyMessage: String {
    switch self {
    case .nothing:
      return "Nobody has asked for anything. Be first."
    case .query:
      return "Nobody has asked for this yet."
    case .statuses:
      return "No request is in the statuses you picked. Others are on the board — show every status to see them."
    case .queryAndStatuses:
      return "Nothing in the statuses you picked matches that search. Show every status to search the whole board."
    }
  }

  /// The line under the way in to the composer, at the end of a board that does have rows on it.
  ///
  /// Both filtered cases warn before they invite. The composer exists to catch a duplicate before
  /// it is written, and a status filter can hide the very request that would have caught it — the
  /// duplicate is on the board, it is just `shipped` and the reader is looking at `open`.
  var listFooter: String {
    switch self {
    case .nothing:
      return "Not on the board? Ask for it."
    case .query:
      return "Vote for one of these if it already says it — duplicates split the demand."
    case .statuses:
      return "This is one slice of the board. Show every status before asking, or you may be asking twice."
    case .queryAndStatuses:
      return "These matches are from one slice of the board. Show every status before asking, or you may be asking twice."
    }
  }
}
