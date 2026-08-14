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
  let statuses: [DRRequestStatus]

  /// Whether the board is ranked by demand or by recency.
  let sort: DRRequestSort

  // MARK: - State

  /// Every request loaded so far, in server order, with later pages appended.
  var requests: [DRFeatureRequest] = []

  /// Free text over title and body, empty for the whole board.
  ///
  /// Settable, unlike the statuses and the sort, because searching is not a different board: it
  /// is the same ranking and the same page shape, which is what lets one renderer show both.
  /// Changing it takes effect on the next `load()` — the cursor a search handed back does not
  /// address the results of another query.
  var query: String = ""

  /// `true` while the first page is being fetched.
  var isLoading: Bool = false

  /// `true` while a deeper page is being fetched.
  var isLoadingMore: Bool = false

  /// Whether the server reported another page. Starts `true` so the first `load()` is
  /// allowed.
  var hasMore: Bool = true

  /// Whether a first `load()` has finished, whether or not it succeeded. What separates "not
  /// read yet" from "read, and the board is empty".
  var hasLoaded: Bool = false

  /// The failure from the most recent page fetch, cleared when a fresh `load()` starts.
  var loadError: Error?

  /// `true` while a vote is being written. One at a time: two votes racing would settle on
  /// whichever answer arrived last rather than on the last tap.
  var isWriting: Bool = false

  /// The failure from the most recent write, cleared when the next write starts.
  var writeError: Error?

  // MARK: - Derived

  /// Whether what is held is the answer to what the search field now says.
  ///
  /// The board's search task fires again every time its view is built, and its view is built again
  /// whenever anything above it redraws. Reading this before reloading is what stops that from
  /// discarding every page after the first, and the reader's place in them with it.
  var isShowingQuery: Bool {
    hasLoaded && query == loadedQuery
  }

  // MARK: - Private state

  /// The opaque continuation the previous page handed back.
  private var cursor: String = ""

  /// The query the pages now held were read for.
  ///
  /// Kept rather than assumed equal to ``query``: the field moves while a read is suspended, and
  /// what is on screen answers whichever question was being asked when that read started.
  private var loadedQuery: String = ""

  // MARK: - Init

  /// - Parameters:
  ///   - client: The client the board reads through.
  ///   - statuses: Which statuses to cover, or empty for everything still on the board.
  ///   - sort: Whether to rank by demand or by recency.
  init(
    client: DifferentRequestsClient,
    statuses: [DRRequestStatus],
    sort: DRRequestSort
  ) {
    self.client = client
    self.statuses = statuses
    self.sort = sort
  }

  // MARK: - Loading

  /// Discards everything loaded and fetches the first page for whatever ``query`` now says.
  ///
  /// Returns immediately when a read is already running — and that read finishes the job, because
  /// it reads again for any query typed while it was suspended. Returning without that, a search
  /// entered while the first page was still in flight would be dropped and stay dropped: this
  /// store outlives the screen that asked, so nothing rebuilds it and asks again.
  func load() async {
    if isLoading { return }
    isLoading = true
    defer {
      isLoading = false
      hasLoaded = true
    }

    repeat {
      loadedQuery = query
      loadError = nil
      requests = []
      cursor = ""
      hasMore = true
      await fetchPage()
    } while loadedQuery != query
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
      let requested: String? = cursor.isEmpty ? nil : cursor
      let page = try await client.requests(
        statuses: statuses,
        sort: sort,
        query: query,
        cursor: requested
      )
      requests.append(contentsOf: page.requests)
      cursor = page.nextCursor
      hasMore = !page.nextCursor.isEmpty
    } catch {
      loadError = error
    }
  }

  // MARK: - Writes

  /// Adds the caller's vote to one request, or takes it back when it is already there.
  ///
  /// Which of the two is decided from the row as it is held before the call. The row is then
  /// found again by id after the write answers, rather than by an index taken before it: a
  /// `load()` can replace the whole array while the call is suspended, and an index from before
  /// the suspension would address a different request or run past the end. A row that is gone by
  /// then is left gone — the vote landed, and the next page it appears in will say so.
  ///
  /// What the write returned replaces the row whole. A count incremented locally is wrong the
  /// moment anyone else votes.
  func toggleVote(requestID: String) async {
    if isWriting { return }
    guard let current = requests.first(where: { $0.id == requestID }) else { return }
    isWriting = true
    writeError = nil
    defer { isWriting = false }

    do {
      let written: DRFeatureRequest
      if current.viewer.voted {
        written = try await client.clearVote(requestID: requestID).request
      } else {
        written = try await client.vote(requestID: requestID).request
      }
      if let index = requests.firstIndex(where: { $0.id == written.id }) {
        requests[index] = written
      }
    } catch {
      writeError = error
    }
  }
}
