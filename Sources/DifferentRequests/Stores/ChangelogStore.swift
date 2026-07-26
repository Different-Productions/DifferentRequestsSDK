import DifferentRequestsProtos
import Foundation

/// Backs the changelog: published notes about what shipped, newest first.
///
/// Wraps `DifferentRequestsClient.changelog(cursor:)` with cursor pagination driven by the
/// response's `nextCursor`, which the server leaves empty on the last page. The first page comes
/// from `load()` and deeper pages from `loadMore()`; only one page is in flight at a time, so a
/// fast scroll cannot queue duplicate requests.
///
/// Drafts never arrive here — presence of a published stamp is what makes an entry public, and
/// that is decided by the server — so there is nothing to filter on the way in.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class ChangelogStore {

  // MARK: - Inputs

  /// The client every call goes through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// Every entry loaded so far, in server order, with later pages appended.
  var entries: [DRChangelogEntry] = []

  /// `true` while the first page is being fetched.
  var isLoading: Bool = false

  /// `true` while a deeper page is being fetched.
  var isLoadingMore: Bool = false

  /// Whether the server reported another page. Starts `true` so the first `load()` is allowed.
  var hasMore: Bool = true

  /// Whether a first `load()` has finished, whether or not it succeeded. What separates "not
  /// read yet" from "read, and nothing has been published".
  var hasLoaded: Bool = false

  /// The failure from the most recent page fetch, cleared when a fresh `load()` starts.
  var loadError: Error?

  // MARK: - Private state

  /// The opaque continuation the previous page handed back.
  private var cursor: String = ""

  // MARK: - Init

  /// - Parameter client: The client the changelog reads through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Discards everything loaded and fetches the first page.
  ///
  /// Returns immediately when a first-page load is already running.
  func load() async {
    if isLoading { return }
    isLoading = true
    loadError = nil
    entries = []
    cursor = ""
    hasMore = true
    defer {
      isLoading = false
      hasLoaded = true
    }
    await fetchPage()
  }

  /// Appends the next page.
  ///
  /// Returns immediately when the server reported no further page, or when a first-page load or
  /// another append is already running.
  func loadMore() async {
    if !hasMore || isLoading || isLoadingMore { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    await fetchPage()
  }

  /// Fetches one page at the current cursor, appends it, and advances the cursor.
  ///
  /// A failure publishes `loadError` and leaves the cursor where it was, so the same page is
  /// retried rather than skipped.
  private func fetchPage() async {
    do {
      let requested: String? = cursor.isEmpty ? nil : cursor
      let page = try await client.changelog(cursor: requested)
      entries.append(contentsOf: page.entries)
      cursor = page.nextCursor
      hasMore = !page.nextCursor.isEmpty
    } catch {
      loadError = error
    }
  }
}
