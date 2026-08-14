import DifferentRequestsProtos
import Foundation

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

  /// Which request the screen is about.
  let requestID: String

  // MARK: - State

  /// The request itself: where its read got to, and what it found.
  ///
  /// `empty` is a server that says there is no such request. Someone arrives here from a
  /// notification kept overnight or a link pasted last month, and "it is not here any more" is a
  /// different screen from "check your connection" — one of them has a Try Again on it that will
  /// never work.
  var read: ReadState<DRFeatureRequest> = .unread

  /// The thread, oldest first — the order a discussion reads in.
  var thread: ReadState<[DRComment]> = .unread

  /// Whether there is another page of the thread, and what became of the last attempt at one.
  var page: PageState = .more

  /// What the last vote, follow or comment is doing, or what it did instead.
  var write: WriteState = .idle

  /// The comment being written, held here so what a reader typed survives a redraw.
  var draft: String = ""

  // MARK: - Private state

  /// The opaque continuation the previous page of the thread handed back.
  private var cursor: String = ""

  // MARK: - Init

  /// - Parameters:
  ///   - client: The client the screen reads and writes through.
  ///   - requestID: Which request the screen is about.
  init(client: DifferentRequestsClient, requestID: String) {
    self.client = client
    self.requestID = requestID
  }

  // MARK: - Loading

  /// Reads the request, then the first page of its thread.
  ///
  /// Returns immediately when either read is already running. What is held stays on screen for
  /// the length of the read: a pull-to-refresh runs on the list's own task, and a list cleared at
  /// the start of a read would take that task with it.
  ///
  /// A request that cannot be read leaves the thread unread rather than failed. There is no
  /// thread worth showing under a request nobody can see, and a second failure would only be a
  /// second thing to say about the first.
  func load() async {
    if read.isReading || thread.isReading { return }
    read = read.whileReading

    do {
      let answer = try await client.request(id: requestID)
      read = .loaded(answer.request)
    } catch {
      read = ReadState(readFailure: error)
      thread = .unread
      page = .done
      return
    }

    thread = thread.whileReading
    cursor = ""
    page = .more

    do {
      let answer = try await client.comments(requestID: requestID, cursor: nil)
      thread = ReadState(page: answer.comments)
      cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      thread = ReadState(readFailure: error)
      page = .done
    }
  }

  /// Appends the next page of the thread.
  ///
  /// Returns immediately when the server reported no further page, when one is already in flight,
  /// or when the screen is being re-read.
  func loadMore() async {
    if page.isReading || page.isDone { return }
    if read.isReading || thread.isReading { return }
    page = .reading

    do {
      let answer = try await client.comments(requestID: requestID, cursor: cursor)
      thread = thread.appending(answer.comments)
      cursor = answer.nextCursor
      page = PageState(nextCursor: answer.nextCursor)
    } catch {
      // The cursor is left where it was, so the retry asks for this page rather than skipping it.
      page = .failed(error)
    }
  }

  // MARK: - Writes

  /// Adds the caller's vote, or takes it back when it is already there.
  ///
  /// Which of the two is decided from what is held before the call and never re-read afterwards:
  /// the answer to a vote is the request the write returned, not a second guess at what it should
  /// now say.
  func toggleVote() async {
    if write.isWriting { return }
    guard let current = read.content else { return }

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
      read = read.holding(written)
      write = .idle
    } catch {
      write = .failed(WriteFailure(attempt: attempt, error: error))
    }
  }

  /// Starts or stops following, so status changes reach this reader without adding demand.
  func toggleFollow() async {
    if write.isWriting { return }
    guard let current = read.content else { return }

    let attempt: WriteAttempt
    if current.viewer.isFollowing {
      attempt = .unfollow
    } else {
      attempt = .follow
    }
    write = .writing(attempt)

    do {
      let written: DRFeatureRequest
      if current.viewer.isFollowing {
        written = try await client.unfollow(requestID: requestID).request
      } else {
        written = try await client.follow(requestID: requestID).request
      }
      read = read.holding(written)
      write = .idle
    } catch {
      write = .failed(WriteFailure(attempt: attempt, error: error))
    }
  }

  /// Whether the draft is worth sending. A blank comment is refused by the server, so it is
  /// refused here instead of sent.
  var canPostComment: Bool {
    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
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
    if write.isWriting { return }
    let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    if body.isEmpty { return }
    write = .writing(.comment)

    do {
      let written = try await client.comment(requestID: requestID, body: body)
      draft = ""
      if page.isDone {
        thread = thread.appending([written.comment])
      }
      write = .idle
    } catch {
      write = .failed(WriteFailure(attempt: .comment, error: error))
    }
  }

  /// Puts away the notice about the last failed write.
  ///
  /// Acknowledgement, not repair: nothing landed, and every control that starts one of these is
  /// on screen either way.
  func acknowledgeWriteFailure() {
    write = .idle
  }
}
