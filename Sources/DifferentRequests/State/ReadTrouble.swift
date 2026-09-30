import Foundation

/// Why a read did not answer, in the terms the person looking at the screen can act on.
enum ReadTrouble {

  /// The phone could not reach the server at all.
  case offline

  /// The server asked for a pause, for this many seconds.
  case tooManyTries(Int)

  /// Anything else, which the person can only wait out.
  case other

  init(error: any Error) {
    if let known = error as? DifferentRequestsError, let seconds = known.retryAfterSeconds {
      self = .tooManyTries(seconds)
    } else if let known = error as? DifferentRequestsError, case .networkError = known {
      self = .offline
    } else {
      self = .other
    }
  }

  /// What the screen says under "Couldn't load".
  var message: String {
    switch self {
    case .offline:
      return String(
        localized: "Your phone isn't connected. Check your connection and try again.",
        bundle: .module,
        comment: "Why a screen couldn't load: no connection"
      )
    case .tooManyTries(let seconds):
      if seconds > 1 {
        return String(
          localized: "Too many tries at once. Try again in \(seconds) seconds.",
          bundle: .module,
          comment: "Why a screen couldn't load: rate limited; the number is seconds to wait"
        )
      }
      return String(
        localized: "Too many tries at once. Try again in a moment.",
        bundle: .module,
        comment: "Why a screen couldn't load: rate limited, briefly"
      )
    case .other:
      return String(
        localized: "Couldn't load right now. Try again in a moment.",
        bundle: .module,
        comment: "Why a screen couldn't load: any other failure"
      )
    }
  }
}
