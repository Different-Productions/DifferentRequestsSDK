import Testing
import Foundation
@testable import DifferentRequests

/// Regression coverage for the optimistic-rollback array helpers.
///
/// The bug these guard against: capturing an array index before an `await`
/// and reusing it after, when a concurrent reload may have shrunk or reordered
/// the array in the meantime — an out-of-bounds trap or a wrong-element write.
@Suite("Optimistic-rollback array helpers")
struct OptimisticRollbackTests {

  private func comment(_ id: String, at seconds: TimeInterval) -> DifferentRequests.Comment {
    DifferentRequests.Comment(
      id: id,
      requestId: "req",
      appId: "app",
      authorId: "author",
      authorDisplayName: "Author",
      isOfficial: false,
      body: "body-\(id)",
      hidden: false,
      createdAt: Date(timeIntervalSince1970: seconds)
    )
  }

  private func notification(_ id: String, read: Bool) -> AppNotification {
    AppNotification(
      id: id,
      requestId: "req",
      type: .comment,
      status: nil,
      commentId: nil,
      read: read,
      createdAt: Date(timeIntervalSince1970: 0)
    )
  }

  // MARK: - reinsertPreservingOrder

  @Test("restores the comment to its original slot when the list is unchanged")
  func reinsertRestoresOriginalPosition() {
    let a = comment("a", at: 1), b = comment("b", at: 2), c = comment("c", at: 3)
    var list = [a, c]
    list.reinsertPreservingOrder(b)
    #expect(list == [a, b, c])
  }

  @Test("re-inserts by order without trapping when the list shrank under an await")
  func reinsertSurvivesShrunkList() {
    let b = comment("b", at: 2), c = comment("c", at: 3)
    // b was at index 1 of [a, b, c]; a concurrent reload shrank the list to [c].
    // The pre-fix code called insert(at: 1) on a 1-element array — a trap.
    var list = [c]
    list.reinsertPreservingOrder(b)
    #expect(list == [b, c])
  }

  @Test("does not duplicate when a reload already restored the element")
  func reinsertSkipsDuplicate() {
    let a = comment("a", at: 1), b = comment("b", at: 2)
    var list = [a, b]
    list.reinsertPreservingOrder(b)
    #expect(list == [a, b])
  }

  @Test("appends when no later element exists")
  func reinsertAppendsNewest() {
    let a = comment("a", at: 1), b = comment("b", at: 2)
    var list = [a]
    list.reinsertPreservingOrder(b)
    #expect(list == [a, b])
  }

  // MARK: - replacingFirst

  @Test("replaces the element matching the id")
  func replacingFirstReplacesMatch() {
    let read = notification("n", read: true)
    var list = [notification("x", read: true), notification("n", read: false)]
    list.replacingFirst(id: "n", with: read)
    #expect(list == [notification("x", read: true), read])
  }

  @Test("is a no-op without trapping when the element is gone")
  func replacingFirstNoOpWhenAbsent() {
    let previous = notification("n", read: false)
    // n was removed by a concurrent reload; the pre-fix code wrote to a stale
    // index — a trap. The rollback must simply find nothing and do nothing.
    var list = [notification("x", read: true)]
    list.replacingFirst(id: "n", with: previous)
    #expect(list == [notification("x", read: true)])
  }
}
