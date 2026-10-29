import Foundation
import SwiftProtobuf

extension Google_Protobuf_Timestamp {
  /// How long ago this was, in words, never in the future.
  ///
  /// The server stamps a row from its own clock, and a phone a second behind reads that stamp as the
  /// future. The stamp is not wrong and the phone is not wrong — what is wrong is telling somebody
  /// their own request has not happened yet.
  ///
  /// Anything under a minute old, or after this device's now, is "Just now". Past that, the
  /// system's own relative wording.
  func ago() -> String {
    if Date().timeIntervalSince(date) < Self.justNowSeconds {
      return String(localized: "Just now", bundle: .module, comment: "When something happened less than a minute ago")
    }
    return date.formatted(.relative(presentation: .named))
  }

  private static let justNowSeconds: TimeInterval = 60
}
