import CryptoKit
import DifferentRequests
import Foundation

/// Stands in for the host developer's own backend: the one place that holds the app's signing
/// secret, and the only thing that can vouch for a person.
///
/// A real integration signs on a server. The secret reaches this app from the environment at run
/// time, so a walk can show a proof being accepted without one ever being built into a binary.
struct DemoBackend {

  /// The app's signing secret, or nothing when this app has none.
  let signingSecret: String?

  /// How long a signed proof lasts: five minutes, well inside the hour the server accepts.
  private static let lifetime: TimeInterval = 300

  /// A proof that this person is who the app claims, or nothing when this app has no secret.
  ///
  /// The external id is part of what is signed, so a proof made for one person cannot be sent for
  /// another.
  func vouchFor(externalID: String) -> DRIdentityProof? {
    guard let signingSecret else {
      return nil
    }
    let expiresAt = Int(Date().addingTimeInterval(Self.lifetime).timeIntervalSince1970)
    let signature = HMAC<SHA256>.authenticationCode(
      for: Data("\(externalID)\n\(expiresAt)".utf8),
      using: SymmetricKey(data: Data(signingSecret.utf8))
    )
    return DRIdentityProof(
      signature: Data(signature).urlSafeBase64String,
      expiresAt: Date(timeIntervalSince1970: TimeInterval(expiresAt))
    )
  }
}
