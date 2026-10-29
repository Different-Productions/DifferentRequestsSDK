import DifferentRequestsProtos
import Foundation

/// A write the SDK cannot name is never made, so it borrows the screen's sentence for any other
/// failure rather than carrying words of its own.
extension WriteAttempt {

  /// What the person who made this write is told when it did not land.
  ///
  /// Each says what did not happen and that the thing they tapped is still there to tap again,
  /// because in every one of these cases it is: the control is on screen, the draft is still in
  /// the field, and nothing has been thrown away.
  func failureMessage() -> String {
    switch self {
    case .vote:
      return String(
        localized: "Your vote didn't go through. Try again.",
        bundle: .module,
        comment: "A vote failed to send"
      )
    case .clearVote:
      return String(
        localized: "Couldn't remove your vote. Try again.",
        bundle: .module,
        comment: "Removing a vote failed to send"
      )
    case .follow:
      return String(
        localized: "Couldn't follow this request. Try again.",
        bundle: .module,
        comment: "Following a request failed to send"
      )
    case .unfollow:
      return String(
        localized: "Couldn't unfollow this request. Try again.",
        bundle: .module,
        comment: "Unfollowing a request failed to send"
      )
    case .comment:
      return String(
        localized: "Your comment didn't send. What you wrote is still here. Choose Send to try again.",
        bundle: .module,
        comment: "A comment failed to send; Send is the button's name"
      )
    case .markRead:
      return String(
        localized: "Couldn't mark this update as read. Try again.",
        bundle: .module,
        comment: "Marking one notification read failed"
      )
    case .markEverythingRead:
      return String(
        localized: "Couldn't mark every update as read. Try again.",
        bundle: .module,
        comment: "Marking every notification read failed"
      )
    case .fileRequest:
      return String(
        localized: "Your request didn't send. What you wrote is still here. Choose Send to try again.",
        bundle: .module,
        comment: "A new request failed to send; Send is the button's name"
      )
    case .unspecified, .UNRECOGNIZED:
      return ReadTrouble().message()
    }
  }

  /// What the person is told when what the write was about is no longer there.
  func goneMessage() -> String {
    switch self {
    case .vote, .clearVote, .follow, .unfollow, .comment:
      return String(
        localized: "This request was removed, so your change wasn't saved.",
        bundle: .module,
        comment: "An action on a request that was deleted"
      )
    case .markRead:
      return String(
        localized: "This update was removed.",
        bundle: .module,
        comment: "Marking read a notification that no longer exists"
      )
    case .markEverythingRead:
      return String(
        localized: "These updates were removed.",
        bundle: .module,
        comment: "Marking read notifications that no longer exist"
      )
    case .fileRequest:
      return String(
        localized: "Your request wasn't accepted. What you wrote is still here, so change it and send it again.",
        bundle: .module,
        comment: "The server refused a new request"
      )
    case .unspecified, .UNRECOGNIZED:
      return ReadTrouble().message()
    }
  }

  /// What the person is told when this app is not letting their account make the write.
  func notAllowedMessage() -> String {
    switch self {
    case .vote, .clearVote:
      return String(
        localized: "Your account can't vote in this app right now.",
        bundle: .module,
        comment: "The app's settings block this account from voting"
      )
    case .follow, .unfollow:
      return String(
        localized: "Your account can't follow requests in this app right now.",
        bundle: .module,
        comment: "The app's settings block this account from following"
      )
    case .comment:
      return String(
        localized: "Your account can't comment in this app right now.",
        bundle: .module,
        comment: "The app's settings block this account from commenting"
      )
    case .markRead, .markEverythingRead:
      return String(
        localized: "Your account can't change Inbox in this app right now.",
        bundle: .module,
        comment: "The app's settings block this account from changing the inbox"
      )
    case .fileRequest:
      return String(
        localized: "Your account can't send requests in this app right now. What you wrote is still here.",
        bundle: .module,
        comment: "The app's settings block this account from sending requests"
      )
    case .unspecified, .UNRECOGNIZED:
      return ReadTrouble().message()
    }
  }

  /// What the person is told when the server refused one field, named as the schema spells it; it
  /// blames one only when it was empty or longer than its limit.
  func fieldMessage(_ field: String) -> String {
    switch self {
    case .comment:
      return String(
        localized: "Your comment is empty or too long. Change it and choose Send.",
        bundle: .module,
        comment: "The server refused a comment's length; Send is the button's name"
      )
    case .fileRequest:
      if field == DRCreateRequestRequest.Field.title {
        return String(
          localized: "The title is empty or too long. Change it and choose Send.",
          bundle: .module,
          comment: "The server refused a new request's title; Send is the button's name"
        )
      }
      if field == DRCreateRequestRequest.Field.body {
        return String(
          localized: "The details are too long. Shorten them and choose Send.",
          bundle: .module,
          comment: "The server refused a new request's detail; Send is the button's name"
        )
      }
      return otherRefusalMessage()
    case .vote, .clearVote, .follow, .unfollow, .markRead, .markEverythingRead, .unspecified, .UNRECOGNIZED:
      return otherRefusalMessage()
    }
  }

  /// What the person is told when the server refused the write for a reason they cannot change by
  /// editing or waiting.
  func otherRefusalMessage() -> String {
    switch self {
    case .vote:
      return String(
        localized: "Your vote couldn't be added to this request.",
        bundle: .module,
        comment: "The server refused a vote"
      )
    case .clearVote:
      return String(
        localized: "Your vote couldn't be removed from this request.",
        bundle: .module,
        comment: "The server refused removing a vote"
      )
    case .follow:
      return String(
        localized: "This request can't be followed right now.",
        bundle: .module,
        comment: "The server refused following a request"
      )
    case .unfollow:
      return String(
        localized: "This request can't be unfollowed right now.",
        bundle: .module,
        comment: "The server refused unfollowing a request"
      )
    case .comment:
      return String(
        localized: "Your comment wasn't accepted. What you wrote is still here, so change it and send it again.",
        bundle: .module,
        comment: "The server refused a comment"
      )
    case .markRead:
      return String(
        localized: "This update couldn't be marked as read. Open Inbox again to refresh it.",
        bundle: .module,
        comment: "The server refused marking one notification read"
      )
    case .markEverythingRead:
      return String(
        localized: "These updates couldn't be marked as read. Open Inbox again to refresh it.",
        bundle: .module,
        comment: "The server refused marking every notification read"
      )
    case .fileRequest:
      return String(
        localized: "Your request wasn't accepted. What you wrote is still here, so change it and send it again.",
        bundle: .module,
        comment: "The server refused a new request"
      )
    case .unspecified, .UNRECOGNIZED:
      return ReadTrouble().message()
    }
  }
}
