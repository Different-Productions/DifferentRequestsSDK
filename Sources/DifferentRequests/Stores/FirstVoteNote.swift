import Foundation

/// "You'll be told when this changes." — said once, under the buttons of the request a person
/// first votes for on this phone.
@MainActor
@Observable
final class FirstVoteNote {

  /// The `UserDefaults` key that remembers a first vote was made on this phone.
  private static let votedKey = "DifferentRequests.firstVoteNoted"

  /// Where the first vote is remembered, so the line is said once per phone.
  let defaults: UserDefaults

  /// The request whose screen says the line, while it does.
  private(set) var requestID: String?

  /// - Parameter defaults: Where the first vote is remembered.
  init(defaults: UserDefaults) {
    self.defaults = defaults
  }

  /// Records a vote that landed on `requestID`, and says the line there if it is the first on this
  /// phone.
  func voted(requestID: String) {
    if defaults.bool(forKey: Self.votedKey) == false {
      defaults.set(true, forKey: Self.votedKey)
      self.requestID = requestID
    }
  }

  /// The screen saying the line went away; it is not said again.
  func putAway() {
    requestID = nil
  }
}
