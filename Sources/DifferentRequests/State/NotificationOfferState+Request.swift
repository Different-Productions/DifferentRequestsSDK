extension NotificationOfferState {

  /// The request the card is drawn under, or nil when there is no card.
  func requestID() -> String? {
    switch card {
    case .offered(let requestID):
      return requestID
    case .failed(let failure):
      return failure.requestID
    case .none:
      return nil
    }
  }
}
