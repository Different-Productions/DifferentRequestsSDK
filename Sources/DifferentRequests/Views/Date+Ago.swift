import Foundation

extension Date {
  /// How long ago this was, in words, never in the future.
  ///
  /// A request filed a moment ago read **"in 1 second"**: the server stamps the row from its own
  /// clock, and a phone a second behind reads that stamp as the future. The stamp is not wrong and
  /// the phone is not wrong — what is wrong is telling somebody their own request has not happened
  /// yet.
  ///
  /// Anything at or after this device's now is "now". Past that, the system's own relative wording,
  /// so it reads in the reader's language without a table of words here.
  var ago: String {
    let now = Date()
    if self >= now {
      return now.formatted(.relative(presentation: .named))
    }
    return formatted(.relative(presentation: .named))
  }
}
