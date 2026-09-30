import DifferentRequestsProtos
import Foundation

extension DRNotification {
  /// The request a tap on this inbox row opens.
  ///
  /// Only duplicate news names somewhere else, and it names it on its own arm, so a tap is never
  /// routed by a target that arrived on news that was not about a duplicate. The request it
  /// duplicates now holds the demand, so that is the one worth opening.
  var destinationID: String {
    switch news {
    case .requestDuplicated(let folded):
      return folded.duplicateOfRequestID
    case .statusChanged, .commentAdded, .none:
      return requestID
    }
  }

  /// The inbox row's headline, in the phone's language, saying what the contract's
  /// `NotificationHeadline` labels say and what the server's push alert says.
  ///
  /// News this SDK version doesn't know still says something happened rather than drawing an empty
  /// row: the request title underneath is what the reader recognizes anyway.
  var headline: String {
    switch news {
    case .statusChanged(let moved):
      return moved.newStatus.movedHeadline
    case .commentAdded:
      return String(localized: "New comment", bundle: .module, comment: "Inbox headline: someone commented on a followed request")
    case .requestDuplicated:
      return String(localized: "Already asked for", bundle: .module, comment: "Inbox headline: the request was merged into another")
    case .none:
      return String(localized: "Something changed", bundle: .module, comment: "Inbox headline for news this version can't name")
    }
  }
}
