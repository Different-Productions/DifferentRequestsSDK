import DifferentRequestsProtos
import Foundation
import SwiftProtobuf

extension DRIdentityProof {
  /// A proof your own backend signed for one person.
  ///
  /// Written here so an integration needs no SwiftProtobuf import to name an instant, and so the
  /// expiry that crosses the wire is the whole second that was signed.
  ///
  /// - Parameters:
  ///   - signature: HMAC-SHA256 over the external id, a newline, and the expiry in whole seconds
  ///     since the epoch, keyed by your app's signing secret and spelled URL-safe base64.
  ///   - expiresAt: When the server stops accepting it. An hour is the longest it accepts, and
  ///     fractions of a second are dropped because they are not part of what was signed.
  public init(signature: String, expiresAt: Date) {
    self.init()
    self.signature = signature
    self.expiresAt = Google_Protobuf_Timestamp(
      seconds: Int64(expiresAt.timeIntervalSince1970),
      nanos: 0
    )
  }
}
