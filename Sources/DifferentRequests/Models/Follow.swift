import Foundation

/// A user's follow of a feature request.
public struct Follow: Sendable, Identifiable, Equatable {
  /// The followed request's ID. Doubles as the stable identifier for this
  /// follow within a single user's followed-requests list.
  public var id: String { requestId }
  /// The request being followed.
  public let requestId: String
  /// The following user's ID.
  public let userId: String
  /// The app this follow belongs to.
  public let appId: String
  /// When the follow was created.
  public let createdAt: Date
}
