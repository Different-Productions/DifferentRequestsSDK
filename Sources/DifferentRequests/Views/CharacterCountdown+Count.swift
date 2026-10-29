extension CharacterCountdown {

  /// The number of characters this names.
  func count() -> Int {
    switch self {
    case .shownFrom:
      return 40
    case .unspecified, .UNRECOGNIZED:
      return 0
    }
  }
}
