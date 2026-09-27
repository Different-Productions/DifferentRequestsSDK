/// Asking Apple for permission to send notifications threw, under the request the card was on.
struct NotificationOfferFailure {

  /// The request the card was drawn under.
  let requestID: String

  /// What `requestAuthorization` threw.
  let error: any Error
}
