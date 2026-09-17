import Foundation

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

extension WriteAttempt {

  /// What the person who made this write is told when it did not land.
  ///
  /// Each says what did not happen and that the thing they tapped is still there to tap again,
  /// because in every one of these cases it is: the control is on screen, the draft is still in
  /// the field, and nothing has been thrown away.
  var failureMessage: String {
    switch self {
    case .vote:
      return "Your vote didn't go through. Try it again."
    case .clearVote:
      return "Couldn't take your vote back. Try it again."
    case .follow:
      return "Couldn't start following this. Try it again."
    case .unfollow:
      return "Couldn't stop following this. Try it again."
    case .comment:
      return "Your comment didn't post. It's still written — send it again."
    case .markRead:
      return "Couldn't mark that read. Try it again."
    case .markEverythingRead:
      return "Couldn't mark everything read. Try it again."
    case .fileRequest:
      return "That didn't send. It's still written — send it again."
    }
  }

  /// What the person is told when the server refused what they wrote, rather than failing to
  /// receive it.
  ///
  /// A separate sentence because "try it again" is a lie here: the same words refused once are
  /// refused every time, and a person told to retry loses the writing to a loop instead of
  /// changing the one thing that would work.
  var refusedMessage: String {
    switch self {
    case .vote:
      return "That vote wasn't allowed."
    case .clearVote:
      return "That vote couldn't be taken back."
    case .follow:
      return "You can't follow that."
    case .unfollow:
      return "You can't unfollow that."
    case .comment:
      return "That comment wasn't accepted. It's still written — change it and send it again."
    case .markRead:
      return "That couldn't be marked read."
    case .markEverythingRead:
      return "Those couldn't be marked read."
    case .fileRequest:
      return "That wasn't accepted. It's still written — change it and send it again."
    }
  }
}
