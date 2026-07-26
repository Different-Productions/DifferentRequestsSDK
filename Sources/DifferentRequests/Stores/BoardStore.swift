import DifferentRequestsProtos
import Foundation

/// Backs the board: the ranked page of requests behind whichever tab or sheet a host app
/// presents it in.
///
/// Wraps `DifferentRequestsClient.listRequests` with cursor pagination driven by the
/// response's `nextCursor`, which the server leaves empty on the last page. The first page
/// comes from `load()` and deeper pages from `loadMore()`; only one page is in flight at a
/// time, so a fast scroll cannot queue duplicate requests.
///
/// The statuses and the sort are given at construction rather than settable, so a filter
/// change is a new store with its own pagination instead of a cursor pointing into a
/// different query's results.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class BoardStore {

  // MARK: - Inputs

  /// The client every call goes through.
  let client: DifferentRequestsClient

  /// Which statuses the board covers. Empty means everything still on it.
  let statuses: [RequestStatus]

  /// Whether the board is ranked by demand or by recency.
  let sort: RequestSort

  // MARK: - State

  /// Every request loaded so far, in server order, with later pages appended.
  var requests: [FeatureRequest] = []

  /// `true` while the first page is being fetched.
  var isLoading: Bool = false

  /// `true` while a deeper page is being fetched.
  var isLoadingMore: Bool = false

  /// Whether the server reported another page. Starts `true` so the first `load()` is
  /// allowed.
  var hasMore: Bool = true

  /// The failure from the most recent page fetch, cleared when a fresh `load()` starts.
  var loadError: Error?

  // MARK: - Private state

  /// The opaque continuation the previous page handed back.
  private var cursor: String = ""

  // MARK: - Init

  /// - Parameters:
  ///   - client: The client the board reads through.
  ///   - statuses: Which statuses to cover, or empty for everything still on the board.
  ///   - sort: Whether to rank by demand or by recency.
  init(
    client: DifferentRequestsClient,
    statuses: [RequestStatus],
    sort: RequestSort
  ) {
    self.client = client
    self.statuses = statuses
    self.sort = sort
  }

  // MARK: - Loading

  /// Discards everything loaded and fetches the first page.
  ///
  /// Returns immediately when a first-page load is already running.
  func load() async {
    if isLoading { return }
    isLoading = true
    loadError = nil
    requests = []
    cursor = ""
    hasMore = true
    defer { isLoading = false }
    await fetchPage()
  }

  /// Appends the next page.
  ///
  /// Returns immediately when the server reported no further page, or when a first-page load
  /// or another append is already running.
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
      let page = try await client.listRequests(
        statuses: statuses,
        sort: sort,
        query: nil,
        cursor: cursor.isEmpty ? nil : cursor
      )
      requests.append(contentsOf: page.requests)
      cursor = page.nextCursor
      hasMore = !page.nextCursor.isEmpty
    } catch {
      loadError = error
    }
  }
}
