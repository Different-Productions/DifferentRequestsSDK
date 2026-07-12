import Foundation

/// A comment on a feature request.
///
/// Comments are a flat list — there is no reply-to-reply threading.
/// Comments from the app's team are marked ``isOfficial`` and should be
/// rendered with a distinct badge.
public struct Comment: Sendable, Identifiable, Equatable {
  /// Unique identifier.
  public let id: String
  /// The request this comment belongs to.
  public let requestId: String
  /// The app this comment belongs to.
  public let appId: String
  /// The author's user ID.
  public let authorId: String
  /// Display name of the author.
  public let authorDisplayName: String
  /// Whether this is an official/team reply, badged and visually prominent.
  public let isOfficial: Bool
  /// The comment text.
  public let body: String
  /// Whether this comment has been moderated. The server excludes hidden
  /// comments from list results, so SDK callers only ever see `false`.
  public let hidden: Bool
  /// When the comment was posted.
  public let createdAt: Date
}
