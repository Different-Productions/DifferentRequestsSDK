extension PageState {

  /// What the answer to a page says about the page after it. The server leaves the cursor empty on
  /// the last one.
  init(nextCursor: String) {
    self.init()
    if nextCursor.isEmpty {
      state = .done(NoMorePages())
    }
  }

  /// Whether there is nothing further to ask for. What a surface checks before drawing anything
  /// under its last row.
  func isDone() -> Bool {
    switch state {
    case .done:
      return true
    case .none, .reading, .failed:
      return false
    }
  }

  /// Whether a page is in flight. What `loadMore()` checks before starting another one.
  func isReading() -> Bool {
    switch state {
    case .reading:
      return true
    case .none, .failed, .done:
      return false
    }
  }
}
