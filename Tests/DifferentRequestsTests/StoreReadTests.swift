import DifferentRequestsProtos
import Foundation
import Testing

@testable import DifferentRequests

/// What a store's read state says after a read that did not answer, and what it must not say.
///
/// Hermetic, and not by pretending. A base URL whose scheme `URLSession` cannot open fails inside
/// `URLSession.data(for:)` without a lookup and without a connection, which reaches the failure
/// branch of every read in the package — including the four whose rpcs an app key alone may make,
/// so the audience gate does not stand in for them.
@MainActor
struct StoreReadTests {

  private func nowhere() throws -> DifferentRequestsClient {
    let base = try #require(URL(string: "differentrequests-nowhere://api.invalid"))
    return .make(appKey: "test-app-key", baseURL: base)
  }

  private func request(id: String) -> DRFeatureRequest {
    var made = DRFeatureRequest()
    made.id = id
    made.title = "Dark mode everywhere"
    return made
  }

  @Test("A first read that fails lands on the state the screen renders from")
  func aFirstReadThatFailsLandsOnTheState() async throws {
    let client = try nowhere()

    let board = BoardStore(client: client, statuses: [], sort: .top)
    await board.load()
    #expect(board.read.failure != nil)
    #expect(board.read.hasRead, "a failed read that stays unread makes .firstRead read forever")
    #expect(board.read.isReading == false)
    #expect(board.page.isDone, "a failed board still offering another page spins under its rows")

    let roadmap = RoadmapStore(client: client)
    await roadmap.load()
    #expect(roadmap.read.failure != nil)
    #expect(roadmap.read.hasRead)

    let changelog = ChangelogStore(client: client)
    await changelog.load()
    #expect(changelog.read.failure != nil)
    #expect(changelog.read.hasRead)

    let detail = RequestDetailStore(client: client, requestID: "r1")
    await detail.load()
    #expect(detail.read.failure != nil)
    #expect(detail.read.hasRead)
    #expect(
      detail.thread.hasRead == false,
      "a request nobody could read reported a thread failure as well as the one that matters"
    )
  }

  @Test("The inbox reads its badge with its page, or it reads neither")
  func theInboxReadsItsBadgeWithItsPage() async throws {
    // Read All appears on the badge. A page that arrives beside a count nobody answered for is a
    // toolbar button offered on a number this client made up.
    let store = InboxStore(client: try nowhere())
    store.unreadCount = 4

    await store.load()

    #expect(store.read.failure != nil)
    #expect(store.unreadCount == 4, "a failed read moved the badge")
  }

  @Test("A page that fails does not take the list with it")
  func aPageThatFailsDoesNotTakeTheListWithIt() async throws {
    // A paged read's failure reported through the state the list is drawn from is a failure
    // nothing renders: a list on screen is what a paged view reads as proof that nothing went
    // wrong, and the spinner under it goes on spinning.
    let store = BoardStore(client: try nowhere(), statuses: [], sort: .top)
    store.read = .loaded([request(id: "r1"), request(id: "r2")])
    store.page = .more

    await store.loadMore()

    #expect(store.page.failure != nil, "the page failed onto something no row draws")
    #expect(store.page.isReading == false, "the row under the list is still claiming to be asking")
    #expect(store.page.isDone == false, "the retry under the last row is not being offered")
    #expect(store.read.held.count == 2, "a failed second page threw away the first")
    #expect(store.read.failure == nil, "a failed page reported itself as the whole board failing")
  }

  @Test("A read already running is not started twice")
  func aReadAlreadyRunningIsNotStartedTwice() async throws {
    // The board's search task fires again on every redraw above it. Without this, each of those
    // would discard every page after the first along with the reader's place in them.
    let store = BoardStore(client: try nowhere(), statuses: [], sort: .top)
    store.read = .refreshing([request(id: "r1")])

    await store.load()

    #expect(store.read.isReading, "the read in flight was replaced by a second one")
    #expect(store.read.held.count == 1)
    #expect(store.read.failure == nil)
  }

  @Test("A thread that fails leaves the request above it readable")
  func aThreadThatFailsLeavesTheRequestReadable() async throws {
    // Two rpcs that fail apart. Telling someone the whole screen is broken because the discussion
    // under it would not load is a lie about what they can see.
    let store = RequestDetailStore(client: try nowhere(), requestID: "r1")
    store.read = .loaded(request(id: "r1"))
    store.thread = .empty

    await store.loadMore()

    #expect(store.page.failure != nil)
    #expect(store.read.failure == nil, "a thread page failing reported the request as unreadable")
    #expect(store.read.hasRead)
  }
}
