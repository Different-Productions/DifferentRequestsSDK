import Foundation

/// An authenticated SDK user.
///
/// Returned by ``DifferentRequestsClient/authenticate(externalUserId:displayName:avatarUrl:)``.
/// The session token is stored internally by the client and injected automatically.
public struct User: Sendable {
  /// The user's internal ID.
  public let userId: String
  /// Session token (managed by the client — you don't need to use this directly).
  public let sessionToken: String
  /// Your app's user ID that you passed to `authenticate`.
  public let externalUserId: String
  /// The user's display name.
  public let displayName: String
  /// URL to the user's avatar, if provided.
  public let avatarUrl: String?
}
