import DifferentRequestsProtos
import Foundation

/// Why the server refused a write, in the terms the person who made it can act on.
enum WriteRefusal {

  /// The request or notification the write was about is no longer there.
  case gone

  /// This app is not letting the person's account make this write.
  case notAllowed

  /// One field was refused, named as the schema spells it: it was empty, or too long.
  case field(String)

  /// A refusal the person cannot change by editing or waiting.
  case other

  /// Nil when the write was not refused: it did not arrive, was rate limited, or failed on the
  /// server's side, and each of those is worth trying again.
  init?(error: any Error) {
    guard let known = error as? DifferentRequestsError, case .api(let refusal) = known else {
      return nil
    }
    switch refusal.reason {
    case .notFound:
      self = .gone
    case .permissionDenied:
      self = .notAllowed
    case .invalidArgument(let blamed):
      self = .field(blamed.field)
    case .malformed, .failedPrecondition, .conflict, .planRequired:
      self = .other
    case .unauthenticated, .rateLimited, .internalFailure, .none:
      return nil
    }
  }
}
