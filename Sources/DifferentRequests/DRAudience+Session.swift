import DifferentRequestsProtos

extension DRAudience {

  /// Whether an rpc with this audience is sent only with the end user's session.
  func needsSession() -> Bool {
    switch self {
    case .endUser:
      true
    case .appKey, .unspecified, .UNRECOGNIZED:
      false
    }
  }
}
