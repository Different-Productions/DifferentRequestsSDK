/// What a write was trying to do, kept so that a failure can name it.
///
/// A reader who tapped a vote and a reader who tapped Send are owed different sentences, and the
/// server's own message is neither: the contract states an `ApiError`'s message is written for
/// whoever is debugging and may name internals. So the sentence is written here, against the
/// thing the person did rather than against the thing that went wrong — they know what they
/// tapped, and what they want to know is whether it counted.
enum WriteAttempt: CaseIterable {

  /// Adding the caller's vote to a request.
  case vote

  /// Taking it back.
  case clearVote

  /// Starting to follow a request without adding demand to it.
  case follow

  /// Stopping.
  case unfollow

  /// Posting a comment on a request.
  case comment

  /// Stamping one notification read.
  case markRead

  /// Stamping every notification read.
  case markEverythingRead

  /// Filing a new request.
  case fileRequest
}
