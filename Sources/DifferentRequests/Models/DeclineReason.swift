import Foundation

/// A decline reason configured for an app.
///
/// When a request is declined, it can be tagged with one of these reasons.
public struct DeclineReason: Sendable, Identifiable {
  /// Unique identifier.
  public let id: String
  /// The app this reason belongs to.
  public let appId: String
  /// Human-readable label (e.g., "Out of scope", "Duplicate").
  public let label: String
  /// Whether this is a built-in default reason.
  public let isDefault: Bool
  /// When this reason was created.
  public let createdAt: Date
}
