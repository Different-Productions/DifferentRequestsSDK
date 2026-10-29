import DifferentRequestsProtos
import Foundation
import SwiftProtobuf

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
/// are compared as one `DRListRequestsRequest` rather than one field at a time.
///
/// Changing one of the three takes effect on the next `load()`. The three methods under *Narrowing*
/// set and re-read in one call, which is what the filter bar taps.
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

  /// Where a vote cast from a row is recorded. A vote also follows the request, so a copy of it
  /// held by the request's own screen is out of date the moment the vote lands.
  let news: NewsAboutRequests

  /// Offered the notification card after a vote cast from a row.
  let notificationOffer: NotificationOffer

  // MARK: - State

  /// What the board is asked, what came back, and where the next page starts.
  var board: BoardState

  /// Where the board's read has got to.
  var status = ReadStatus()

  /// Whether there is another page, and what became of the last attempt at one.
  var page = PageState()

  /// What the last vote is doing, or what it did instead.
  var write = WriteState()

  // MARK: - Init

  /// - Parameters:
  ///   - client: The client the board reads through.
  ///   - news: Where a vote cast here is recorded, so a request's own screen re-reads it.
  ///   - notificationOffer: Offered the notification card after a vote cast here.
  ///   - board: The board as built: which statuses it covers and how it ranks them.
  init(
    client: DifferentRequestsClient,
    news: NewsAboutRequests,
    notificationOffer: NotificationOffer,
    board: BoardState
  ) {
    self.client = client
    self.news = news
    self.notificationOffer = notificationOffer
    self.board = board
  }

  // MARK: - What is being asked

  /// The whole of what the board is being asked for right now, as the contract's own request.
  ///
  /// The cursor is deliberately left empty: it addresses a place inside an answer, not the question
  /// asked, so leaving it off is what makes `==` between two of these mean "the same board" without
  /// a comparison written field by field.
  func question() -> DRListRequestsRequest {
    var asking = DRListRequestsRequest()
    asking.statuses = board.statuses
    asking.sort = board.sort
    asking.query = board.query
    return asking
  }

  /// Whether what is held — or what is already being read — answers the question now being asked.
  ///
  /// The board's search task fires again every time its view is built, and its view is built again
  /// whenever anything above it redraws. Reading this before reloading is what stops that from
  /// discarding every page after the first, and the reader's place in them with it.
  func isCurrent() -> Bool {
    hasRead() && board.asked == question()
  }

  /// Whether a read of the board has finished, whatever it found. A refresh over requests already
  /// held does not make the board unread again.
  func hasRead() -> Bool {
    status.hasRead(holdsContent: board.requests.isEmpty == false)
  }

  /// What was keeping requests off the board when its last read started, which is what an empty
  /// board means.
  ///
  /// Read from the question that read was started for rather than from what the controls now say,
  /// so the sentence on an empty board describes the read that produced it.
  func narrowing() -> BoardNarrowing {
    BoardNarrowing(question: board.asked)
  }

  // MARK: - What can be asked for

  /// Every ranking the board can be asked for, from the contract's own table.
  ///
  /// Filtered to the values that have a spelling in a URL. A value with no spelling cannot be sent,
  /// which is what keeps `unspecified` — the zero every proto enum decodes to by default — out of a
  /// query string. Read from `allCases` rather than listed here, so a ranking the contract adds
  /// reaches the bar by being declared.
  func offeredSorts() -> [DRRequestSort] {
    DRRequestSort.allCases.filter { sort in
      sort.urlToken != nil
    }
  }

  /// Every status the board can be narrowed to, from the contract's own list of what a board shows.
  ///
  /// Not every spellable status is on a board. A duplicate has left it for the request it was
  /// folded into, so asking a board for one asks for something that is not there. Which statuses a
  /// board shows is the contract's to say, so the bar is built from `shownOnABoard`.
  func offeredStatuses() -> [DRRequestStatus] {
    DRRequestStatus.shownOnABoard
  }

  // MARK: - Narrowing

  /// Ranks the board the other way and reads it again.
  ///
  /// Read again rather than re-sorted in place: the board is one page of many, and the top of a
  /// ranking is not something a page of another ranking contains.
  func show(sort: DRRequestSort) async {
    board.sort = sort
    await load()
  }

  /// Adds one status to what the board covers, or drops it when it is already there, then reads
  /// again.
  ///
  /// The kept statuses are rebuilt in the order the contract declares them rather than in the order
  /// they were tapped, so the same set is always spelled the same way in a URL.
  func toggle(status: DRRequestStatus) async {
    let kept = board.statuses
    if kept.contains(status) {
      board.statuses = kept.filter { covered in
        covered != status
      }
    } else {
      board.statuses = offeredStatuses().filter { offered in
        offered == status || kept.contains(offered)
      }
    }
    await load()
  }

  /// Drops every status filter and reads again, leaving whatever is in the search field alone.
  ///
  /// Two narrowings, undone one at a time. Clearing someone's typed search from a control labeled
  /// for statuses would take away words they can see in a field they did not touch.
  func showEveryStatus() async {
    board.statuses = []
    await load()
  }

  // MARK: - Loading

  /// Reads the first page for whatever the board is now being asked, replacing everything held.
  ///
  /// Returns immediately when a read is already running — and that read finishes the job, because
  /// it reads again for any question asked while it was suspended. This store outlives the screen
  /// that asked, so nothing rebuilds it and asks again.
  ///
  /// What is already held stays held for the length of the read. It is replaced by the answer
  /// rather than cleared before the question, so a pull-to-refresh does not take away the list
  /// that is running it.
  func load() async {
    if status.isReading() == false {
      repeat {
        status.state = .reading(Reading())
        board.asked = question()
        board.cursor = ""
        page = PageState()
        await readFirstPage(board.asked)
      } while board.asked != question()
    }
  }

  /// Reads the board again when what is held does not answer the question now being asked, after
  /// letting a burst of typing settle.
  ///
  /// Run from a task keyed on the query, which SwiftUI cancels and restarts on every keystroke.
  /// A canceled wait sends nothing, and a board that already answers the question is left alone, so
  /// a redraw does not throw away the pages after the first.
  func search() async {
    if isCurrent() == false {
      do {
        if board.query.isEmpty == false {
          try await Task.sleep(for: .seconds(board.searchSettleDelay.timeInterval))
        }
        await load()
      } catch {
        // The wait throws only when it is canceled, and a canceled search sends nothing.
      }
    }
  }

  /// Reads the board again when any row it holds was heard to have changed after its copy arrived,
  /// so a request shipped or answered while the board was held is not drawn as it was.
  ///
  /// Read again whole rather than patched: a change moves a request's rank, and can take it off a
  /// board narrowed to the status it left, which only the server's answer says.
  func readAgainIfNewer() async {
    if news.hasNews(about: board) {
      await load()
    }
  }

  /// Appends the next page.
  ///
  /// Returns immediately when the server reported no further page, when one is already in flight,
  /// or when the whole board is being re-read. A page that failed is not one of those: the retry
  /// under the last row is how it is asked for again.
  ///
  /// Asked under the question the last read started for rather than under what the controls now
  /// say. The cursor came back from that question.
  func loadMore() async {
    if page.isReading() == false, page.isDone() == false, status.isReading() == false {
      page.state = .reading(Reading())
      let sentAt = Google_Protobuf_Timestamp(date: Date())

      do {
        let answer = try await fetch(board.asked, cursor: board.cursor)
        board.requests.append(contentsOf: answer.requests)
        stamp(answer.requests, copiedAt: sentAt)
        status.state = .loaded(ReadAnswered())
        board.cursor = answer.nextCursor
        page = PageState(nextCursor: answer.nextCursor)
      } catch {
        // The cursor is left where it was, so the retry asks for this page rather than skipping it.
        page.state = .failed(ReadTrouble(error: error))
      }
    }
  }

  /// Reads page one of `question` and replaces the board with it.
  private func readFirstPage(_ question: DRListRequestsRequest) async {
    let sentAt = Google_Protobuf_Timestamp(date: Date())
    do {
      let answer = try await fetch(question, cursor: "")
      board.requests = answer.requests
      board.copiedAt = [:]
      stamp(answer.requests, copiedAt: sentAt)
      status.state = .loaded(ReadAnswered())
      board.cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      board.requests = []
      board.copiedAt = [:]
      status = ReadStatus(readFailure: error)
      page.state = .done(NoMorePages())
    }
  }

  /// Records that these rows' copies are the server's as of `copiedAt`, the moment the read that
  /// returned them was sent: news that lands while it is in flight is newer than what it returns.
  private func stamp(_ rows: [DRFeatureRequest], copiedAt: Google_Protobuf_Timestamp) {
    for row in rows {
      board.copiedAt[row.id] = copiedAt
    }
  }

  /// One page of `question` at `cursor`, or its first when that is empty.
  ///
  /// The cursor is set on a copy of the question rather than passed beside it, so what goes over
  /// the wire is one message the contract declares.
  private func fetch(
    _ question: DRListRequestsRequest,
    cursor: String
  ) async throws -> DRListRequestsResponse {
    var asking = question
    asking.cursor = cursor
    return try await client.requests(asking)
  }

  // MARK: - Writes

  /// Adds the caller's vote to one request, or takes it back when it is already there.
  ///
  /// Which of the two is decided from the row as it is held before the call. The row is then
  /// found again by id after the write answers, rather than by an index taken before it: a
  /// `load()` can replace the whole board while the call is suspended.
  ///
  /// The row flips before the call, so the tile answers the tap at once. What the write returned
  /// then replaces the row whole, and a refused write puts back the row as it was held.
  func toggleVote(requestID: String) async {
    let matchingRequest = board.requests.first { request in
      request.id == requestID
    }
    if write.isWriting() == false, let current = matchingRequest {
      let attempt: WriteAttempt
      if current.viewer.voted {
        attempt = .clearVote
      } else {
        attempt = .vote
      }
      write.state = .writing(attempt)
      land(withVoteFlipped(current))

      do {
        let written: DRFeatureRequest
        if current.viewer.voted {
          written = try await client.clearVote(requestID: requestID).request
        } else {
          written = try await client.vote(requestID: requestID).request
        }
        land(written)
        // The row just landed is the change being announced, so its copy is as new as the news.
        let landed = Date()
        news.heard(aboutRequest: requestID, at: landed)
        stamp([written], copiedAt: Google_Protobuf_Timestamp(date: landed))
        write = WriteState()
        if written.viewer.voted {
          await notificationOffer.votedOrFollowed(requestID: requestID)
        }
      } catch {
        land(current)
        write.state = .failed(WriteFailure(attempt: attempt, error: error))
      }
    }
  }

  /// Puts `row` in place of the request held under its id, without clearing the mark that says a
  /// read is in flight.
  private func land(_ row: DRFeatureRequest) {
    board.requests = board.requests.replacingRow(row, identifiedBy: \.id)
    status = status.afterWrite()
  }

  /// The row as it reads the moment its tile is tapped, held until the write answers with the
  /// server's own row or is refused.
  private func withVoteFlipped(_ request: DRFeatureRequest) -> DRFeatureRequest {
    var flipped = request
    if request.viewer.voted {
      flipped.viewer.voted = false
      if request.voteCount > 0 {
        flipped.voteCount = request.voteCount - 1
      }
    } else {
      flipped.viewer.voted = true
      flipped.voteCount = request.voteCount + 1
    }
    return flipped
  }

  /// Puts away the notice about the last failed vote.
  ///
  /// Acknowledgement, not repair: the vote still did not land, and the control that casts it is
  /// on screen either way.
  func acknowledgeWriteFailure() {
    write = WriteState()
  }
}
