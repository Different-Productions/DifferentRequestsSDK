/// Where the "Get told when this changes?" card is, for the request it was offered under.
enum NotificationOfferState {

  /// No card is up.
  case hidden

  /// The card is up under the request whose vote or follow brought it.
  case offered(requestID: String)

  /// Apple's prompt could not be asked; the card says so under the same request.
  case failed(NotificationOfferFailure)
}

extension NotificationOfferState {

  /// The request the card is drawn under, or nil when there is no card.
  var requestID: String? {
    switch self {
    case .hidden:
      return nil
    case .offered(let requestID):
      return requestID
    case .failed(let failure):
      return failure.requestID
    }
  }
}
