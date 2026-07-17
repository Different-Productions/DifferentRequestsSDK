import Foundation

/// Rollback helpers for the optimistic-update state models.
///
/// Each operation re-resolves its target by identity at call time rather than
/// trusting an index captured before an `await`. Because the models are
/// `@MainActor`, a concurrent `load()`/`loadMore()` can replace the backing
/// array while a network call is suspended; an index captured before the
/// suspension may then point past the end (a trap) or at a different element
/// (silent corruption) by the time the rollback runs.
extension Array where Element: Identifiable {

  /// Replace the first element whose `id` matches `id` with `replacement`.
  /// Does nothing when no such element remains — the row a rollback would
  /// restore is already gone, so there is nothing to restore.
  mutating func replacingFirst(id: Element.ID, with replacement: Element) {
    if let index = firstIndex(where: { $0.id == id }) {
      self[index] = replacement
    }
  }
}

extension Array where Element == Comment {

  /// Re-insert `comment` at the position that preserves the list's oldest-first
  /// `createdAt` ordering. Skips insertion when an element with the same `id`
  /// is already present, so a concurrent reload that already restored the
  /// comment does not leave a duplicate.
  mutating func reinsertPreservingOrder(_ comment: Comment) {
    if contains(where: { $0.id == comment.id }) { return }
    if let index = firstIndex(where: { $0.createdAt > comment.createdAt }) {
      insert(comment, at: index)
    } else {
      append(comment)
    }
  }
}
