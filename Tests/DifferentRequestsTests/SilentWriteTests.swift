import DifferentRequestsProtos
import Foundation
import Testing

@testable import DifferentRequests

/// Every write this SDK makes, refused, once each.
///
/// A refused write that reaches nothing a view renders is a person tapping, a control not moving,
/// and no explanation of why. These assert the opposite for each of the eight: that the refusal
/// reaches `store.write`, that it says which write it was, and that nothing on screen moved as
/// though the write had landed.
///
/// Hermetic, and not by pretending. Every rpc these writes make declares `END_USER` audience, and
/// `DifferentRequestsClient.perform` refuses one of those before anything is sent when no session
/// exists. So these walk the real failure path — the one a host app that forgot `createSession`
/// walks — without a network, a server or a stub.
@MainActor
struct SilentWriteTests {

  private func client() -> DifferentRequestsClient {
    .make(appKey: "test-app-key")
  }

  private func request(id: String, voted: Bool, following: Bool) -> DRFeatureRequest {
    var made = DRFeatureRequest()
    made.id = id
    made.title = "Dark mode everywhere"
    made.voteCount = 128
    var viewer = DRViewerState()
    viewer.voted = voted
    viewer.isFollowing = following
    made.viewer = viewer
    return made
  }

  /// Unread, which is the only state the dot that marks one read is drawn in.
  private func unreadNotification(id: String) -> DRNotification {
    var made = DRNotification()
    made.id = id
    made.requestID = "r1"
    made.requestTitle = "Dark mode everywhere"
    var moved = DRStatusChangedNews()
    moved.newStatus = .planned
    made.news = .statusChanged(moved)
    return made
  }

  @Test("A vote on the board that fails says so, and the count does not move")
  func aBoardVoteThatFailsSaysSo() async {
    let store = BoardStore(client: client(), statuses: [], sort: .top)
    store.read = .loaded([request(id: "r1", voted: false, following: false)])

    await store.toggleVote(requestID: "r1")

    let failure = store.write.failure
    #expect(failure != nil, "the vote was refused and the board has nothing to say about it")
    #expect(failure?.attempt == .vote)
    #expect(failure?.message == WriteAttempt.vote.failureMessage)
    #expect(store.write.isWriting == false, "a failed write left every control on the board inert")
    #expect(store.read.held.first?.voteCount == 128, "a count moved for a vote that never landed")
    #expect(store.read.held.first?.viewer.voted == false)
  }

  @Test("An un-vote that fails says which direction it was")
  func aBoardUnvoteThatFailsSaysWhichDirectionItWas() async {
    let store = BoardStore(client: client(), statuses: [], sort: .top)
    store.read = .loaded([request(id: "r1", voted: true, following: true)])

    await store.toggleVote(requestID: "r1")

    #expect(store.write.failure?.attempt == .clearVote)
    #expect(store.write.failure?.message == WriteAttempt.clearVote.failureMessage)
  }

  @Test("A vote on one request's own screen says so, and the request stays readable")
  func aVoteOnOneRequestThatFailsSaysSo() async {
    let store = RequestDetailStore(client: client(), requestID: "r1")
    store.read = .loaded(request(id: "r1", voted: false, following: false))

    await store.toggleVote()

    #expect(store.write.failure?.attempt == .vote)
    #expect(store.read.hasRead, "a failed vote took the request off the screen it was cast on")
    #expect(store.read.failure == nil)
  }

  @Test("A follow and an unfollow that fail each say which they were")
  func aFollowThatFailsSaysSo() async {
    let notFollowing = RequestDetailStore(client: client(), requestID: "r1")
    notFollowing.read = .loaded(request(id: "r1", voted: false, following: false))
    await notFollowing.toggleFollow()
    #expect(notFollowing.write.failure?.attempt == .follow)

    let following = RequestDetailStore(client: client(), requestID: "r1")
    following.read = .loaded(request(id: "r1", voted: true, following: true))
    await following.toggleFollow()
    #expect(following.write.failure?.attempt == .unfollow)
  }

  @Test("A comment that fails keeps what was written, because the sentence says to send it again")
  func aCommentThatFailsKeepsWhatWasWritten() async {
    let store = RequestDetailStore(client: client(), requestID: "r1")
    store.read = .loaded(request(id: "r1", voted: false, following: false))
    store.thread = .empty
    store.draft = "Yes please, my eyes are going"

    await store.postComment()

    #expect(store.write.failure?.attempt == .comment)
    #expect(
      store.draft == "Yes please, my eyes are going",
      "the draft was cleared for a comment that never posted"
    )
    #expect(store.thread.held.isEmpty, "a comment that failed joined the thread anyway")
  }

  @Test("Marking one notification read that fails says so, and the row stays unread")
  func markingOneReadThatFailsSaysSo() async {
    let store = InboxStore(client: client())
    store.read = .loaded([unreadNotification(id: "n1")])
    store.unreadCount = 3

    await store.markRead(notificationID: "n1")

    #expect(store.write.failure?.attempt == .markRead)
    #expect(
      store.read.held.first?.hasReadAt == false,
      "a dot went away for a stamp that never landed"
    )
    #expect(store.unreadCount == 3, "the badge dropped for a stamp that never landed")
  }

  @Test("Marking everything read that fails says so, and nothing is re-read")
  func markingEverythingReadThatFailsSaysSo() async {
    let store = InboxStore(client: client())
    store.read = .loaded([unreadNotification(id: "n1")])
    store.unreadCount = 3

    await store.markAllRead()

    #expect(store.write.failure?.attempt == .markEverythingRead)
    #expect(store.read.held.count == 1)
    #expect(store.unreadCount == 3)
  }

  @Test("Filing that fails keeps the composer exactly as it was typed")
  func filingThatFailsKeepsTheComposer() async {
    let store = SubmitStore(client: client())
    store.begin(title: "dark mode")
    store.body = "Please. My eyes."

    await store.submit()

    #expect(store.write.failure?.attempt == .fileRequest)
    #expect(store.submitted == nil, "the sheet would have dismissed on a request nobody filed")
    #expect(store.title == "dark mode")
    #expect(store.body == "Please. My eyes.")
  }

  @Test("Every writing store can be told the notice was seen")
  func everyWritingStoreCanBeToldTheNoticeWasSeen() async {
    let board = BoardStore(client: client(), statuses: [], sort: .top)
    board.read = .loaded([request(id: "r1", voted: false, following: false)])
    await board.toggleVote(requestID: "r1")
    #expect(board.write.failure != nil)
    board.acknowledgeWriteFailure()
    #expect(board.write.failure == nil)

    let inbox = InboxStore(client: client())
    inbox.read = .loaded([unreadNotification(id: "n1")])
    await inbox.markRead(notificationID: "n1")
    #expect(inbox.write.failure != nil)
    inbox.acknowledgeWriteFailure()
    #expect(inbox.write.failure == nil)

    let detail = RequestDetailStore(client: client(), requestID: "r1")
    detail.read = .loaded(request(id: "r1", voted: false, following: false))
    await detail.toggleVote()
    #expect(detail.write.failure != nil)
    detail.acknowledgeWriteFailure()
    #expect(detail.write.failure == nil)

    let submission = SubmitStore(client: client())
    submission.begin(title: "dark mode")
    await submission.submit()
    #expect(submission.write.failure != nil)
    submission.acknowledgeWriteFailure()
    #expect(submission.write.failure == nil)
  }

  @Test("A write refused because another is running is not reported as a failure")
  func oneWriteAtATimeIsNotASecondFailure() async {
    // Each store takes one write at a time. The refusal is not something the server said no to,
    // and publishing it as a failure would put a sentence on screen about a write nobody made.
    let store = BoardStore(client: client(), statuses: [], sort: .top)
    store.read = .loaded([request(id: "r1", voted: false, following: false)])
    store.write = .writing(.vote)

    await store.toggleVote(requestID: "r1")

    #expect(store.write.isWriting, "the write in flight was replaced by a second one's refusal")
    #expect(store.write.failure == nil)
  }

  @Test("A control tapped while its surface is refreshing is attempted, not dropped")
  func aWriteDuringARefreshIsStillAttempted() async {
    // A refreshing surface draws exactly what a loaded one draws, so every control on it is there
    // to be tapped. A store that only accepts writes from the settled state refuses them without
    // saying anything.
    let detail = RequestDetailStore(client: client(), requestID: "r1")
    detail.read = .refreshing(request(id: "r1", voted: false, following: false))
    await detail.toggleVote()
    #expect(detail.write.failure?.attempt == .vote, "a vote cast during a refresh went nowhere")

    let board = BoardStore(client: client(), statuses: [], sort: .top)
    board.read = .refreshing([request(id: "r1", voted: false, following: false)])
    await board.toggleVote(requestID: "r1")
    #expect(board.write.failure?.attempt == .vote)

    let inbox = InboxStore(client: client())
    inbox.read = .refreshing([unreadNotification(id: "n1")])
    await inbox.markRead(notificationID: "n1")
    #expect(inbox.write.failure?.attempt == .markRead)
  }

  @Test("A vote for a row the board is not holding does nothing at all")
  func aVoteForARowTheBoardDoesNotHoldDoesNothing() async {
    // A reload can replace the whole board between the tap and the store reading it. There is
    // nothing to toggle and nothing failed, so there is nothing to say.
    let store = BoardStore(client: client(), statuses: [], sort: .top)
    store.read = .loaded([request(id: "r1", voted: false, following: false)])

    await store.toggleVote(requestID: "r9")

    #expect(store.write.failure == nil)
    #expect(store.write.isWriting == false)
  }
}
