extension PillFill {

  /// The tint where `chosen` is in effect, and gray where it is not.
  init(chosen: Bool) {
    if chosen {
      self = .tint
    } else {
      self = .gray
    }
  }

  /// The color the button's label is drawn in.
  func labelRole() -> ColorRole {
    switch self {
    case .tint:
      return .onTint
    case .gray, .unspecified, .UNRECOGNIZED:
      return .label
    }
  }

  /// The color behind the label.
  func backgroundRole() -> ColorRole {
    switch self {
    case .tint:
      return .tint
    case .gray, .unspecified, .UNRECOGNIZED:
      return .fill
    }
  }
}
