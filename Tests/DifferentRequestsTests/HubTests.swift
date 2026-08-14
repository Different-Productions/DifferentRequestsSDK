import DifferentRequestsProtos
import Testing
@testable import DifferentRequests

/// The hub is what makes a screen's state older than the screen. A SwiftUI view is a value that is
/// thrown away and built again on every redraw above it, so anything it constructs is gone with it;
/// these assert the two things that stop that — the same store for the same request, and one
/// composer that is opened rather than rebuilt.
///
/// Nothing here touches the network. A client is built because the stores need one to hold, and no
/// method that would call through it is invoked.
@MainActor
struct HubTests {

  @Test("One request keeps one store, however many times a rebuilt screen asks for it")
  func oneRequestKeepsOneStore() {
    let hub = DifferentRequestsHub(client: .make(appKey: "test-app-key"))

    let opened = hub.detail(requestID: "req-1")
    opened.draft = "half a comment"

    let reopened = hub.detail(requestID: "req-1")

    #expect(reopened === opened, "a rebuilt screen must land on the store it left")
    #expect(reopened.draft == "half a comment", "a redraw took the comment being written")
  }

  @Test("Two requests do not share a store")
  func twoRequestsDoNotShareAStore() {
    let hub = DifferentRequestsHub(client: .make(appKey: "test-app-key"))

    let first = hub.detail(requestID: "req-1")
    first.draft = "half a comment"
    let second = hub.detail(requestID: "req-2")

    #expect(second !== first)
    #expect(second.draft.isEmpty, "a draft leaked from one request's screen into another's")
    #expect(second.requestID == "req-2")
  }

  @Test("The composer opens on what the board was searched for")
  func theComposerOpensOnWhatWasSearched() {
    let hub = DifferentRequestsHub(client: .make(appKey: "test-app-key"))

    hub.board.query = "dark mode"
    hub.beginSubmission()

    #expect(hub.submission.title == "dark mode")
    #expect(hub.submission.body.isEmpty)
  }

  @Test("The composer opens empty from an unsearched board, and keeps nothing from the last one")
  func theComposerOpensEmptyFromAnUnsearchedBoard() {
    let hub = DifferentRequestsHub(client: .make(appKey: "test-app-key"))

    hub.board.query = "dark mode"
    hub.beginSubmission()
    hub.submission.body = "and while you are in there"

    hub.board.query = ""
    hub.beginSubmission()

    #expect(hub.submission.title.isEmpty)
    #expect(hub.submission.body.isEmpty, "the last request was still sitting in the composer")
    #expect(hub.submission.submitted == nil, "a filed request would make the composer look done")
  }

  @Test("A blank title cannot be filed")
  func aBlankTitleCannotBeFiled() {
    let hub = DifferentRequestsHub(client: .make(appKey: "test-app-key"))
    hub.beginSubmission()

    #expect(hub.submission.canSubmit == false, "an untouched composer offers Submit")

    hub.submission.title = "   \n\t "
    #expect(hub.submission.canSubmit == false, "whitespace is not a request")

    hub.submission.title = "Dark mode everywhere"
    #expect(hub.submission.canSubmit)
  }

  @Test("A board that has never read is not showing anything, whatever the field says")
  func nothingIsShownBeforeTheFirstRead() {
    let hub = DifferentRequestsHub(client: .make(appKey: "test-app-key"))

    #expect(hub.board.isShowingQuery == false)

    hub.board.query = "dark mode"
    #expect(hub.board.isShowingQuery == false, "an unread board claiming to answer a search")
  }

  @Test("The board the hub builds excludes no status")
  func theBoardTheHubBuildsExcludesNoStatus() {
    let hub = DifferentRequestsHub(client: .make(appKey: "test-app-key"))

    // An empty filter is the whole board. Read from the contract's own table rather than from a
    // list written here, so a status added to the contract is covered by being declared.
    for status in DRRequestStatus.allCases {
      #expect(
        hub.board.statuses.contains(status) == false,
        "\(status.rawValue) is filtered out of the board the hub builds"
      )
    }
  }
}
