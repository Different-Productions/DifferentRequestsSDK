import Foundation

extension Date {
  /// How long ago this was, in words, never in the future.
  ///
  /// A request filed a moment ago read **"in 1 second"**: the server stamps the row from its own
  /// clock, and a phone a second behind reads that stamp as the future. The stamp is not wrong and
  /// the phone is not wrong — what is wrong is telling somebody their own request has not happened
  /// yet.
  ///
  /// Anything under a minute old, or after this device's now, is "Just now". Past that, the
  /// system's own relative wording.
  var ago: String {
    if Date().timeIntervalSince(self) < Self.justNowSeconds {
      return String(localized: "Just now", bundle: .module, comment: "When something happened less than a minute ago")
    }
    return formatted(.relative(presentation: .named))
  }

  private static let justNowSeconds: TimeInterval = 60
}
