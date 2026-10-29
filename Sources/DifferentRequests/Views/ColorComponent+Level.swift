extension ColorComponent {

  /// The component level this names.
  func level() -> UInt32 {
    switch self {
    case .largest:
      return 255
    case .unspecified, .UNRECOGNIZED:
      return 0
    }
  }
}
