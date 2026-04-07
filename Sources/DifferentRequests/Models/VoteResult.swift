import Foundation

/// The result of a vote operation.
///
/// Contains the confirmed vote (if any) and the updated score
/// so the UI can reflect the change immediately.
public struct VoteResult: Sendable {
  /// The confirmed vote record, or `nil` if the vote was removed.
  public let vote: Vote?
  /// The request's updated score after this vote.
  public let newScore: Int
}
