extension LuminanceWeight {

  /// The number this names.
  func weight() -> Float {
    switch self {
    case .red:
      return 0.2126
    case .green:
      return 0.7152
    case .blue:
      return 0.0722
    case .blackContrastThreshold:
      return 0.183
    case .unspecified, .UNRECOGNIZED:
      return 0
    }
  }
}
