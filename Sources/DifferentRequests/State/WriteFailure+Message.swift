import DifferentRequestsProtos

extension WriteFailure {

  /// What the person who made the write is told. Written against what they did, never from the
  /// server's message, which the contract says may name internals.
  ///
  /// A write the server refused is never worth repeating and one that did not arrive always is, so
  /// the contract's reason picks which sentence, never a status code.
  func message() -> String {
    switch answer.reason {
    case .notFound:
      return attempt.goneMessage()
    case .permissionDenied:
      return attempt.notAllowedMessage()
    case .invalidArgument(let blamed):
      return attempt.fieldMessage(blamed.field)
    case .malformed, .failedPrecondition, .conflict, .planRequired:
      return attempt.otherRefusalMessage()
    case .unauthenticated, .rateLimited, .internalFailure, .none:
      return attempt.failureMessage()
    }
  }
}
