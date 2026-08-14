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
/// Three states, one per thing that can be happening: the board is being read, a further page is
/// being read, a vote is being written. They are separate values because they are true at the
/// same time — a vote is cast on a board that is already loaded, and folding the two together
/// would mean a failed vote erasing the list it was cast on.
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

  /// The board itself: where its read got to, and the requests it found.
  var read: ReadState<[DRFeatureRequest]> = .unread

  /// Whether there is another page, and what became of the last attempt at one.
  var page: PageState = .more

  /// What the last vote is doing, or what it did instead.
  var write: WriteState = .idle

  /// Free text over title and body, empty for the whole board.
  ///
  /// Settable, unlike the statuses and the sort, because searching is not a different board: it
  /// is the same ranking and the same page shape, which is what lets one renderer show both.
  /// Changing it takes effect on the next `load()` — the cursor a search handed back does not
  /// address the results of another query.
  var query: String = ""

  // MARK: - Derived

  /// Whether what is held is the answer to what the search field now says.
  ///
  /// The board's search task fires again every time its view is built, and its view is built again
  /// whenever anything above it redraws. Reading this before reloading is what stops that from
  /// discarding every page after the first, and the reader's place in them with it.
  var isShowingQuery: Bool {
    read.hasRead && query == loadedQuery
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

  /// Reads the first page for whatever ``query`` now says, replacing everything held.
  ///
  /// Returns immediately when a read is already running — and that read finishes the job, because
  /// it reads again for any query typed while it was suspended. Returning without that, a search
  /// entered while the first page was still in flight would be dropped and stay dropped: this
  /// store outlives the screen that asked, so nothing rebuilds it and asks again.
  ///
  /// What is already held stays held for the length of the read. It is replaced by the answer
  /// rather than cleared before the question, so a pull-to-refresh does not take away the list
  /// that is running it.
  func load() async {
    if read.isReading { return }

    repeat {
      read = read.whileReading
      loadedQuery = query
      cursor = ""
      page = .more
      await readFirstPage()
    } while loadedQuery != query
  }

  /// Appends the next page.
  ///
  /// Returns immediately when the server reported no further page, when one is already in flight,
  /// or when the whole board is being re-read. A page that failed is not one of those: the retry
  /// under the last row is how it is asked for again.
  func loadMore() async {
    if page.isReading || page.isDone { return }
    if read.isReading { return }
    page = .reading

    do {
      let answer = try await fetch(cursor: cursor)
      read = read.appending(answer.requests)
      cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      // The cursor is left where it was, so the retry asks for this page rather than skipping it.
      page = .failed(error)
    }
  }

  /// Reads page one and replaces the board with it.
  private func readFirstPage() async {
    do {
      let answer = try await fetch(cursor: "")
      read = ReadState(page: answer.requests)
      cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      read = ReadState(readFailure: error)
      page = .done
    }
  }

  /// One page at `cursor`, or the first when it is empty.
  private func fetch(cursor: String) async throws -> DRListRequestsResponse {
    let requested: String? = cursor.isEmpty ? nil : cursor
    return try await client.requests(
      statuses: statuses,
      sort: sort,
      query: query,
      cursor: requested
    )
  }

  // MARK: - Writes

  /// Adds the caller's vote to one request, or takes it back when it is already there.
  ///
  /// Which of the two is decided from the row as it is held before the call. The row is then
  /// found again by id after the write answers, rather than by an index taken before it: a
  /// `load()` can replace the whole board while the call is suspended.
  ///
  /// What the write returned replaces the row whole. A count incremented locally is wrong the
  /// moment anyone else votes.
  func toggleVote(requestID: String) async {
    if write.isWriting { return }
    guard let current = read.held.first(where: { $0.id == requestID }) else { return }

    let attempt: WriteAttempt
    if current.viewer.voted {
      attempt = .clearVote
    } else {
      attempt = .vote
    }
    write = .writing(attempt)

    do {
      let written: DRFeatureRequest
      if current.viewer.voted {
        written = try await client.clearVote(requestID: requestID).request
      } else {
        written = try await client.vote(requestID: requestID).request
      }
      read = read.replacing(written, identifiedBy: { $0.id })
      write = .idle
    } catch {
      write = .failed(WriteFailure(attempt: attempt, error: error))
    }
  }

  /// Puts away the notice about the last failed vote.
  ///
  /// Acknowledgement, not repair: the vote still did not land, and the control that casts it is
  /// on screen either way.
  func acknowledgeWriteFailure() {
    write = .idle
  }
}
