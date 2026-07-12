import Foundation

/// A registered APNs device token, returned after registering or refreshing.
///
/// The server never echoes the raw token back — only a hash of it, to avoid
/// putting device-identifying material in a response body unnecessarily.
public struct Device: Sendable {
  /// SHA-256 hex digest of the registered token.
  public let tokenHash: String
  /// When this token was first registered.
  public let createdAt: Date
  /// When this token was last registered or refreshed.
  public let updatedAt: Date
}
