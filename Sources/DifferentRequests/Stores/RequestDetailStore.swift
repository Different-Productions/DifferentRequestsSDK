import DifferentRequestsProtos
import Foundation
import SwiftProtobuf

/// Backs one request's own screen: the request, its thread, and the writes that act on both.
///
/// The request comes from `DifferentRequestsClient.request(id:)` and the thread from
/// `comments(requestID:cursor:)` with cursor pagination driven by the response's `nextCursor`,
/// which the server leaves empty on the last page. The first page comes from `load()` and
/// deeper pages from `loadMore()`; only one page is in flight at a time, so a fast scroll
/// cannot queue duplicate requests.
///
/// Two reads rather than one, because they are two rpcs that fail apart: a request that arrives
/// beside a thread that did not is still worth reading, and telling someone the whole screen is
/// broken because the discussion under it would not load is a lie about what they can see.
///
/// Every write here answers with the request as the server now holds it, and that answer
/// replaces what is held rather than being merged into it. A count adjusted locally is wrong
/// from the moment anyone else votes.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class RequestDetailStore {

  // MARK: - Inputs

  /// The client every call goes through.
  let client: DifferentRequestsClient

  /// Offered the notification card after a vote or follow here.
  let notificationOffer: NotificationOffer

  /// Says "You'll get an update in Inbox when this request changes." after the first vote on this phone.
  let firstVoteNote: FirstVoteNote

  // MARK: - State

  /// Which request, when the copy held arrived, its thread, where the next page of it starts, and
  /// the comment being written.
  var detail: RequestDetailState

  /// Where the request's read has got to.
  ///
  /// Answered with no request in ``answer`` is a server that says there is no such request.
  /// Someone arrives here from a notification kept overnight or a link pasted last month, and "it
  /// is not here any more" is a different screen from "check your connection" — one of them has a
  /// Try again on it that will never work.
  var status = ReadStatus()

  /// The request as the server last answered with it. Holds no request until a read finds one.
  var answer = DRGetRequestResponse()

  /// Where the thread's read has got to.
  var threadStatus = ReadStatus()

  /// Whether this app takes comments, and how far the asking got.
  ///
  /// Not a Pro gate: comments are free on every plan, and this is off when the tenant has chosen
  /// not to moderate a discussion. The same question all the same — a composer under a thread that
  /// does not take comments is a field whose Send has one possible answer, and whether that answer
  /// is a refusal today is the server's to change without telling anyone.
  var commenting = PlanState()

  /// Whether there is another page of the thread, and what became of the last attempt at one.
  var page = PageState()

  /// What the last vote, follow or comment is doing, or what it did instead.
  var write = WriteState()

  // MARK: - Init

  /// - Parameters:
  ///   - client: The client the screen reads and writes through.
  ///   - detail: Which request the screen is about, nothing about it read yet.
  ///   - notificationOffer: Offered the notification card after a vote or follow here.
  ///   - firstVoteNote: Says the one-time line after the first vote on this phone.
  init(
    client: DifferentRequestsClient,
    detail: RequestDetailState,
    notificationOffer: NotificationOffer,
    firstVoteNote: FirstVoteNote
  ) {
    self.client = client
    self.detail = detail
    self.notificationOffer = notificationOffer
    self.firstVoteNote = firstVoteNote
  }

  // MARK: - Loading

  /// Reads the request, then the first page of its thread, then whether this app takes comments.
  ///
  /// Returns immediately when either read is already running. What is held stays on screen for
  /// the length of the read: a pull-to-refresh runs on the list's own task, and a list cleared at
  /// the start of a read would take that task with it.
  ///
  /// A request that cannot be read leaves the thread unread rather than failed, and leaves the
  /// question of commenting unasked. There is no thread worth showing under a request nobody can
  /// see and nothing to comment on, and a second failure would only be a second thing to say about
  /// the first.
  ///
  /// Commenting is asked about last because it is the last thing needed: the discussion is what
  /// someone came here to read, and whether they may answer it matters at the moment they have
  /// finished reading. It is usually free by then — the client answers it from the first read any
  /// gated surface made.
  func load() async {
    if status.isReading() == false, threadStatus.isReading() == false {
      status.state = .reading(Reading())
      // Stamped when asked, not when answered: news that lands while the read is in flight is
      // newer than the copy it returns.
      let sentAt = Google_Protobuf_Timestamp(date: Date())

      do {
        answer = try await client.request(id: detail.requestID)
        status.state = .loaded(ReadAnswered())
        detail.readAt = sentAt
        await loadThread()
        await loadCommenting()
      } catch {
        answer = DRGetRequestResponse()
        status = ReadStatus(readFailure: error)
        detail.comments = []
        threadStatus = ReadStatus()
        page.state = .done(NoMorePages())
      }
    }
  }

  /// Whether a read of the request has finished, whatever it found. A refresh over the request
  /// already held does not make it unread again.
  func hasRead() -> Bool {
    status.hasRead(holdsContent: answer.hasRequest)
  }

  /// Reads the first page of the discussion under a request that was just read.
  private func loadThread() async {
    threadStatus.state = .reading(Reading())
    detail.cursor = ""
    page = PageState()

    do {
      let thread = try await client.comments(requestID: detail.requestID, cursor: detail.cursor)
      detail.comments = thread.comments
      threadStatus.state = .loaded(ReadAnswered())
      detail.cursor = thread.nextCursor
      page = PageState(nextCursor: thread.nextCursor)
    } catch {
      detail.comments = []
      threadStatus = ReadStatus(readFailure: error)
      page.state = .done(NoMorePages())
    }
  }

  /// Asks whether this app takes comments.
  ///
  /// Its own method as well as part of ``load()``, because it is the retry behind the one failure
  /// the composer's own slot can show. A reader who could not be told whether the discussion is
  /// open is owed a way to ask again that does not re-read the request and the thread they are
  /// already looking at.
  func loadCommenting() async {
    if commenting.needsReading() {
      commenting.state = .reading(Reading())

      do {
        let answer = try await client.config()
        commenting = PlanState(surface: .comments, response: answer)
      } catch {
        commenting.state = .failed(ReadTrouble(error: error))
      }
    }
  }

  /// Appends the next page of the thread.
  ///
  /// Returns immediately when the server reported no further page, when one is already in flight,
  /// or when the screen is being re-read.
  func loadMore() async {
    let isIdle = status.isReading() == false && threadStatus.isReading() == false
    if page.isReading() == false, page.isDone() == false, isIdle {
      page.state = .reading(Reading())

      do {
        let thread = try await client.comments(requestID: detail.requestID, cursor: detail.cursor)
        detail.comments.append(contentsOf: thread.comments)
        threadStatus.state = .loaded(ReadAnswered())
        detail.cursor = thread.nextCursor
        page = PageState(nextCursor: thread.nextCursor)
      } catch {
        // The cursor is left where it was, so the retry asks for this page rather than skipping it.
        page.state = .failed(ReadTrouble(error: error))
      }
    }
  }

  // MARK: - Writes

  /// Adds the caller's vote, or takes it back when it is already there.
  ///
  /// Which of the two is decided from what is held before the call and never re-read afterwards:
  /// the answer to a vote is the request the write returned, not a second guess at what it should
  /// now say.
  func toggleVote() async {
    if write.isWriting() == false, answer.hasRequest {
      let current = answer.request
      let attempt: WriteAttempt
      if current.viewer.voted {
        attempt = .clearVote
      } else {
        attempt = .vote
      }
      write.state = .writing(attempt)

      do {
        let written: DRFeatureRequest
        if current.viewer.voted {
          written = try await client.clearVote(requestID: detail.requestID).request
        } else {
          written = try await client.vote(requestID: detail.requestID).request
        }
        land(written)
        write = WriteState()
        if written.viewer.voted {
          firstVoteNote.voted(requestID: detail.requestID)
          await notificationOffer.votedOrFollowed(requestID: detail.requestID)
        }
      } catch {
        write.state = .failed(WriteFailure(attempt: attempt, error: error))
      }
    }
  }

  /// Starts or stops following, so status changes reach this reader without adding demand.
  func toggleFollow() async {
    if write.isWriting() == false, answer.hasRequest {
      let current = answer.request
      let attempt: WriteAttempt
      if current.viewer.isFollowing {
        attempt = .unfollow
      } else {
        attempt = .follow
      }
      write.state = .writing(attempt)

      do {
        let written: DRFeatureRequest
        if current.viewer.isFollowing {
          written = try await client.unfollow(requestID: detail.requestID).request
        } else {
          written = try await client.follow(requestID: detail.requestID).request
        }
        land(written)
        write = WriteState()
        if written.viewer.isFollowing {
          await notificationOffer.votedOrFollowed(requestID: detail.requestID)
        }
      } catch {
        write.state = .failed(WriteFailure(attempt: attempt, error: error))
      }
    }
  }

  /// Holds `written` as the request, without clearing the mark that says a read is in flight.
  private func land(_ written: DRFeatureRequest) {
    answer.request = written
    status = status.afterWrite()
  }

  /// How many characters the draft has left, from the limit the contract declares. Negative once
  /// it is over.
  func commentCharactersLeft() -> CharactersLeftContent {
    CharactersLeftContent(limit: DRCreateCommentRequest.TextLimit.body, typed: detail.draft)
  }

  /// Whether the draft is worth sending. A blank or overlong comment is refused by the server, so
  /// it is refused here instead of sent.
  func canPostComment() -> Bool {
    detail.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
      && commentCharactersLeft().left >= 0
  }

  /// Posts the draft and clears it.
  ///
  /// The written comment joins the thread only once the whole thread is loaded. A thread is
  /// read oldest first, so appending to a partly read one would put the new comment ahead of
  /// comments not yet fetched; left alone, it arrives in its own place when the reader pages to
  /// the end.
  ///
  /// A failure leaves the draft exactly as typed. The message says to send it again, and there
  /// has to be something to send.
  func postComment() async {
    let body = detail.draft.trimmingCharacters(in: .whitespacesAndNewlines)
    if write.isWriting() == false, body.isEmpty == false {
      write.state = .writing(.comment)

      do {
        let written = try await client.comment(requestID: detail.requestID, body: body)
        detail.draft = ""
        if page.isDone() {
          detail.comments.append(written.comment)
          threadStatus.state = .loaded(ReadAnswered())
        }
        write = WriteState()
      } catch {
        write.state = .failed(WriteFailure(attempt: .comment, error: error))
      }
    }
  }

  /// Puts away the notice about the last failed write.
  ///
  /// Acknowledgement, not repair: nothing landed, and every control that starts one of these is
  /// on screen either way.
  func acknowledgeWriteFailure() {
    write = WriteState()
  }
}
