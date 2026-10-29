import DifferentRequestsProtos

extension DRApiError {

  /// Why a read the server answered with this did not land: a pause the server asked for, or
  /// anything else, which the person can only wait out.
  func readTrouble() -> ReadTrouble {
    switch reason {
    case .rateLimited(let limited):
      var trouble = ReadTrouble()
      trouble.tooManyTries = limited
      return trouble
    case .invalidArgument, .malformed, .unauthenticated, .permissionDenied, .notFound, .failedPrecondition, .conflict,
      .planRequired, .internalFailure, .none:
      return ReadTrouble()
    }
  }
}
