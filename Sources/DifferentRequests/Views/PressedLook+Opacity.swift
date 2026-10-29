extension PressedLook {

  /// The opacity a control is drawn at in this state.
  func opacity() -> Double {
    switch self {
    case .pressed:
      return 0.6
    case .atRest, .unspecified, .UNRECOGNIZED:
      return 1
    }
  }
}
