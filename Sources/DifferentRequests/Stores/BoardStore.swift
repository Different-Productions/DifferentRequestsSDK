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
/// Three things narrow what comes back — the statuses covered, the ranking, and the search text —
/// and all three are settable, because a narrowing is not a different board. It is the same ranking
/// and the same page shape, which is what lets one renderer show all of them. What they share is a
/// cursor: a cursor addresses the results of the question it was handed back for, so changing any of
/// them throws away the pages held under the old one and starts again at page one. That is why they
/// are compared as a single ``BoardQuestion`` rather than one property at a time.
///
/// Changing one of the three takes effect on the next `load()`. The three methods under *Narrowing*
/// set and re-read in one call, which is what the filter bar taps; a host app setting a property
/// directly is asking for the change to apply to the next read it starts.
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

  // MARK: - What is being asked

  /// Which statuses the board covers. Empty means everything still on it.
  var statuses: [DRRequestStatus]

  /// Whether the board is ranked by demand or by recency.
  var sort: DRRequestSort

  /// Free text over title and body, empty for the whole board.
  var query: String

  // MARK: - State

  /// The board itself: where its read got to, and the requests it found.
  var read: ReadState<[DRFeatureRequest]> = .unread

  /// Whether there is another page, and what became of the last attempt at one.
  var page: PageState = .more

  /// What the last vote is doing, or what it did instead.
  var write: WriteState = .idle

  // MARK: - Derived

  /// The whole of what the board is being asked for right now.
  var question: BoardQuestion {
    BoardQuestion(statuses: statuses, sort: sort, query: query)
  }

  /// Whether what is held — or what is already being read — answers the question now being asked.
  ///
  /// The board's search task fires again every time its view is built, and its view is built again
  /// whenever anything above it redraws. Reading this before reloading is what stops that from
  /// discarding every page after the first, and the reader's place in them with it.
  var isCurrent: Bool {
    read.hasRead && asked == question
  }

  /// What was keeping requests off the board when its last read started, which is what an empty
  /// board means.
  ///
  /// Read from the question that read was started for rather than from what the controls now say,
  /// so the sentence on an empty board describes the read that produced it.
  var narrowing: BoardNarrowing {
    BoardNarrowing(question: asked)
  }

  // MARK: - What can be asked for

  /// Every ranking the board can be asked for, from the contract's own table.
  ///
  /// Filtered to the values that have a spelling in a URL. A value with no spelling cannot be sent,
  /// which is what keeps `unspecified` — the zero every proto enum decodes to by default — out of a
  /// query string rather than merely discouraged. Read from `allCases` rather than listed here, so
  /// a ranking the contract adds reaches the bar by being declared and nothing here has to be
  /// remembered.
  var offeredSorts: [DRRequestSort] {
    DRRequestSort.allCases.filter { $0.urlToken != nil }
  }

  /// Every status the board can be narrowed to, on the same terms and from the same table.
  var offeredStatuses: [DRRequestStatus] {
    DRRequestStatus.allCases.filter { $0.urlToken != nil }
  }

  // MARK: - Private state

  /// The opaque continuation the previous page handed back.
  private var cursor: String = ""

  /// The question the last read was started for.
  ///
  /// Kept rather than assumed equal to ``question``: the controls move while a read is suspended,
  /// and what is on screen answers whichever question was being asked when that read started.
  private var asked: BoardQuestion

  // MARK: - Init

  /// - Parameters:
  ///   - client: The client the board reads through.
  ///   - statuses: Which statuses to cover, or empty for everything still on the board.
  ///   - sort: Whether to rank by demand or by recency.
  ///
  /// A board starts unsearched, and starts having asked nothing else — ``asked`` is the question
  /// this was built to ask, so `loadMore()` before any `load()` pages the board as constructed
  /// rather than paging nothing.
  init(
    client: DifferentRequestsClient,
    statuses: [DRRequestStatus],
    sort: DRRequestSort
  ) {
    self.client = client
    self.statuses = statuses
    self.sort = sort
    self.query = ""
    self.asked = BoardQuestion(statuses: statuses, sort: sort, query: "")
  }

  // MARK: - Narrowing

  /// Ranks the board the other way and reads it again.
  ///
  /// Read again rather than re-sorted in place: the board is one page of many, and the top of a
  /// ranking is not something a page of another ranking contains.
  func show(sort: DRRequestSort) async {
    self.sort = sort
    await load()
  }

  /// Adds one status to what the board covers, or drops it when it is already there, then reads
  /// again.
  ///
  /// The kept statuses are rebuilt in the order the contract declares them rather than in the order
  /// they were tapped, so the same set is always spelled the same way in a URL. That rebuild also
  /// drops anything the contract gives no spelling to, which the client would have dropped from the
  /// query string anyway — this only makes the store agree with what was sent.
  func toggle(status: DRRequestStatus) async {
    let kept = statuses
    if kept.contains(status) {
      statuses = kept.filter { $0 != status }
    } else {
      statuses = offeredStatuses.filter { $0 == status || kept.contains($0) }
    }
    await load()
  }

  /// Drops every status filter and reads again, leaving whatever is in the search field alone.
  ///
  /// Two narrowings, undone one at a time. Clearing someone's typed search from a control labelled
  /// for statuses would take away words they can see in a field they did not touch.
  func showEveryStatus() async {
    statuses = []
    await load()
  }

  // MARK: - Loading

  /// Reads the first page for whatever the board is now being asked, replacing everything held.
  ///
  /// Returns immediately when a read is already running — and that read finishes the job, because
  /// it reads again for any question asked while it was suspended. Returning without that, a search
  /// entered or a filter tapped while the first page was still in flight would be dropped and stay
  /// dropped: this store outlives the screen that asked, so nothing rebuilds it and asks again.
  ///
  /// What is already held stays held for the length of the read. It is replaced by the answer
  /// rather than cleared before the question, so a pull-to-refresh does not take away the list
  /// that is running it.
  func load() async {
    if read.isReading { return }

    repeat {
      read = read.whileReading
      asked = question
      cursor = ""
      page = .more
      await readFirstPage(asked)
    } while asked != question
  }

  /// Appends the next page.
  ///
  /// Returns immediately when the server reported no further page, when one is already in flight,
  /// or when the whole board is being re-read. A page that failed is not one of those: the retry
  /// under the last row is how it is asked for again.
  ///
  /// Asked under ``asked`` rather than under what the controls now say. The cursor came back from
  /// that question, and handing it to a different one asks the server to continue a list it never
  /// started.
  func loadMore() async {
    if page.isReading || page.isDone { return }
    if read.isReading { return }
    page = .reading

    do {
      let answer = try await fetch(asked, cursor: cursor)
      read = read.appending(answer.requests)
      cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      // The cursor is left where it was, so the retry asks for this page rather than skipping it.
      page = .failed(error)
    }
  }

  /// Reads page one of `question` and replaces the board with it.
  private func readFirstPage(_ question: BoardQuestion) async {
    do {
      let answer = try await fetch(question, cursor: "")
      read = ReadState(page: answer.requests)
      cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      read = ReadState(readFailure: error)
      page = .done
    }
  }

  /// One page of `question` at `cursor`, or its first when that is empty.
  private func fetch(
    _ question: BoardQuestion,
    cursor: String
  ) async throws -> DRListRequestsResponse {
    let requested: String? = cursor.isEmpty ? nil : cursor
    return try await client.requests(
      statuses: question.statuses,
      sort: question.sort,
      query: question.query,
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
