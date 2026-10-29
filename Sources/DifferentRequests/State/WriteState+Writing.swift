extension WriteState {

  /// Whether a write is in flight. What a store checks before starting another one, and what the
  /// controls on a surface disable themselves from.
  func isWriting() -> Bool {
    switch state {
    case .writing:
      return true
    case .none, .failed:
      return false
    }
  }

  /// The failure to tell the reader about, or nil when there is nothing to say.
  func failure() -> WriteFailure? {
    switch state {
    case .failed(let failure):
      return failure
    case .none, .writing:
      return nil
    }
  }
}
