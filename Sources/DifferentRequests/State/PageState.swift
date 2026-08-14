import Foundation

/// Whether a paged surface has another page, and what happened to the last attempt at one.
///
/// Three things to say, not two, and the third is the one that matters. A page that fails has
/// nowhere to go when the only failure on a store is the one its first read sets: by the time a
/// second page is asked for there is a list on screen, and a list on screen is what a paged view
/// takes as proof that nothing went wrong. The reader is left with a spinner under the last row
/// that never stops, waiting on a page nothing will ask for again.
enum PageState {

  /// The server reported another page and nothing is being done about it yet.
  case more

  /// The next page is being fetched.
  case reading

  /// The last attempt at the next page did not answer.
  ///
  /// The cursor still points at that page, so a retry asks for it again rather than skipping it.
  case failed(any Error)

  /// The server reported no further page. It leaves the cursor empty to say so.
  case done
}

extension PageState {

  /// What the answer to a page says about the page after it.
  init(nextCursor: String) {
    if nextCursor.isEmpty {
      self = .done
    } else {
      self = .more
    }
  }

  /// Whether there is nothing further to ask for. What a surface checks before drawing anything
  /// under its last row.
  var isDone: Bool {
    switch self {
    case .done:
      return true
    case .more, .reading, .failed:
      return false
    }
  }

  /// Whether a page is in flight. What `loadMore()` checks before starting another one.
  var isReading: Bool {
    switch self {
    case .reading:
      return true
    case .more, .failed, .done:
      return false
    }
  }

  /// The failure the last page attempt ended in, for a host app that wants to log it. Nil in
  /// every other state.
  var failure: (any Error)? {
    switch self {
    case .more, .reading, .done:
      return nil
    case .failed(let error):
      return error
    }
  }
}
