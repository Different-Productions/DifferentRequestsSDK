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

  /// The request, once a read has answered. Kept across a refresh so the screen does not empty
  /// while it reloads.
  var request: DRFeatureRequest?

  /// The thread so far, oldest first — the order a discussion reads in — with later pages
  /// appended.
  var comments: [DRComment] = []

  /// The comment being written, held here so what a reader typed survives a redraw.
  var draft: String = ""

  /// `true` while the request and the first page of its thread are being fetched.
  var isLoading: Bool = false

  /// `true` while a deeper page of the thread is being fetched.
  var isLoadingMore: Bool = false

  /// Whether the server reported another page of the thread. Starts `true` so the first
  /// `load()` is allowed.
  var hasMore: Bool = true

  /// Whether a first `load()` has finished, whether or not it succeeded. What separates "not
  /// read yet" from "read, and this is all there is".
  var hasLoaded: Bool = false

  /// The failure from the most recent read, cleared when a fresh `load()` starts.
  var loadError: Error?

  /// `true` while a vote, a follow, or a comment is being written. One write at a time: two
  /// votes racing would settle on whichever answer arrived last rather than on the last tap.
  var isWriting: Bool = false

  /// The failure from the most recent write, cleared when the next write starts.
  var writeError: Error?

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

  /// Reads the request and the first page of its thread.
  ///
  /// Returns immediately when a read is already running.
  func load() async {
    if isLoading { return }
    isLoading = true
    loadError = nil
    comments = []
    cursor = ""
    hasMore = true
    defer {
      isLoading = false
      hasLoaded = true
    }

    do {
      let answer = try await client.request(id: requestID)
      request = answer.request
    } catch {
      loadError = error
      // No thread read: a request that cannot be read has no thread worth showing, and a
      // second failure would only replace the one already published.
      return
    }
    await fetchPage()
  }

  /// Appends the next page of the thread.
  ///
  /// Returns immediately when the server reported no further page, or when a read or another
  /// append is already running.
  func loadMore() async {
    if !hasMore || isLoading || isLoadingMore { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    await fetchPage()
  }

  /// Fetches one page of the thread at the current cursor, appends it, and advances the cursor.
  ///
  /// A failure publishes `loadError` and leaves the cursor where it was, so the same page is
  /// retried rather than skipped.
  private func fetchPage() async {
    do {
      let requested: String? = cursor.isEmpty ? nil : cursor
      let page = try await client.comments(requestID: requestID, cursor: requested)
      comments.append(contentsOf: page.comments)
      cursor = page.nextCursor
      hasMore = !page.nextCursor.isEmpty
    } catch {
      loadError = error
    }
  }

  // MARK: - Writes

  /// Adds the caller's vote, or takes it back when it is already there.
  ///
  /// Which of the two is decided from what is held before the call and never re-read
  /// afterwards: the answer to a vote is the request the write returned, not a second guess at
  /// what it should now say.
  func toggleVote() async {
    if isWriting { return }
    guard let current = request else { return }
    isWriting = true
    writeError = nil
    defer { isWriting = false }

    do {
      if current.viewer.voted {
        let written = try await client.clearVote(requestID: requestID)
        request = written.request
      } else {
        let written = try await client.vote(requestID: requestID)
        request = written.request
      }
    } catch {
      writeError = error
    }
  }

  /// Starts or stops following, so status changes reach this reader without adding demand.
  func toggleFollow() async {
    if isWriting { return }
    guard let current = request else { return }
    isWriting = true
    writeError = nil
    defer { isWriting = false }

    do {
      if current.viewer.isFollowing {
        let written = try await client.unfollow(requestID: requestID)
        request = written.request
      } else {
        let written = try await client.follow(requestID: requestID)
        request = written.request
      }
    } catch {
      writeError = error
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
  func postComment() async {
    if isWriting { return }
    let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    if body.isEmpty { return }
    isWriting = true
    writeError = nil
    defer { isWriting = false }

    do {
      let written = try await client.comment(requestID: requestID, body: body)
      draft = ""
      if hasMore == false {
        comments.append(written.comment)
      }
    } catch {
      writeError = error
    }
  }
}
