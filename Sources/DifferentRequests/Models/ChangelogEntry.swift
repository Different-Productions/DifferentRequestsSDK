import Foundation

/// A published changelog entry ("What's New"), authored in the console.
///
/// The SDK only ever sees published entries — drafts are console-only.
public struct ChangelogEntry: Sendable, Identifiable, Equatable {
  /// Unique identifier.
  public let id: String
  /// Entry headline.
  public let title: String
  /// Entry body.
  public let body: String
  /// IDs of the requests this entry resolves.
  public let requestIds: [String]
  /// When this entry was published.
  public let publishedAt: Date
  /// When this entry was authored.
  public let createdAt: Date
  /// When this entry was last modified.
  public let updatedAt: Date
}
