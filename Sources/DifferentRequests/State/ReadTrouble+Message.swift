import Foundation

extension ReadTrouble {

  /// What the screen says under its heading.
  func message() -> String {
    switch reason {
    case .offline:
      return String(
        localized: "You're offline. Check your connection and try again.",
        bundle: .module,
        comment: "Why a screen couldn't load: no connection"
      )
    case .tooManyTries(let limited):
      let seconds = Int(limited.retryAfterSeconds)
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
    case .none:
      return String(
        localized: "Something went wrong on the server. Try again in a moment.",
        bundle: .module,
        comment: "Why a screen couldn't load: any other failure"
      )
    }
  }
}
