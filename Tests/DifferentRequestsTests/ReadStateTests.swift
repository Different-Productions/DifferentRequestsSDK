import DifferentRequestsProtos
import Foundation
import Testing

@testable import DifferentRequests

/// A surface has four outcomes and a view has to draw all four. `ReadState` is where that is
/// decided once, for every screen in the package, so that no screen can assemble its own set and
/// leave one out — and the one left out is always the surface that read and found nothing, drawn
/// as a blank page indistinguishable from one still reading.
///
/// These walk the value itself: no client, no network, no store. Six cases, and the four
/// properties a view and a store read them through.
struct ReadStateTests {

  /// A request with an id, since that is what a list holds and what a write comes back as.
  private func request(id: String, title: String) -> DRFeatureRequest {
    var made = DRFeatureRequest()
    made.id = id
    made.title = title
    return made
  }

  @Test("The four outcomes are four different states, and nothing collapses two of them")
  func theFourOutcomesAreFourDifferentStates() {
    let nothing: ReadState<[String]> = .unread
    let first: ReadState<[String]> = .reading
    let broken: ReadState<[String]> = .failed(URLError(.notConnectedToInternet))
    let none: ReadState<[String]> = .empty
    let some: ReadState<[String]> = .loaded(["one"])
    let again: ReadState<[String]> = .refreshing(["one"])

    // Not read yet, and read-and-there-is-nothing, are the pair a view most easily draws as one.
    #expect(nothing.hasRead == false)
    #expect(none.hasRead)
    #expect(none.held.isEmpty)
    #expect(none.failure == nil, "an empty surface is not a failed one")

    // Reading with nothing to show, and reading over something already on screen.
    #expect(first.isReading)
    #expect(first.held.isEmpty)
    #expect(again.isReading)
    #expect(again.held == ["one"], "a refresh that empties the list takes its own task with it")

    // Failed, which is the only case that carries an error.
    #expect(broken.failure != nil)
    #expect(broken.hasRead, "a read that failed has still finished; retrying is the reader's call")
    #expect(broken.isReading == false)

    #expect(some.held == ["one"])
    #expect(some.isReading == false)
    #expect(some.failure == nil)
  }

  @Test("hasRead is false only until the first answer, whatever that answer was")
  func hasReadIsFalseOnlyUntilTheFirstAnswer() {
    // What `.firstRead` keys its task on. It must not move while a read runs, or the task cancels
    // the read that moved it — and it must not go back to false on a refresh, or every redraw
    // over a loaded surface would re-read it.
    let before: [ReadState<[String]>] = [.unread, .reading]
    for state in before {
      #expect(state.hasRead == false)
    }

    let after: [ReadState<[String]>] = [
      .failed(URLError(.timedOut)),
      .empty,
      .loaded(["one"]),
      .refreshing(["one"]),
    ]
    for state in after {
      #expect(state.hasRead, "a first read would fire again over a surface that has answered")
    }
  }

  @Test("A read starting keeps whatever is already held on screen")
  func aRefreshKeepsWhatIsAlreadyHeld() {
    let fromNothing: [ReadState<[String]>] = [
      .unread,
      .reading,
      .failed(URLError(.timedOut)),
      .empty,
    ]
    for state in fromNothing {
      let started = state.whileReading
      #expect(started.isReading)
      #expect(started.held.isEmpty)
      #expect(started.failure == nil, "a retry that still shows the last failure has not started")
    }

    let held = ["one", "two"]
    let fromSomething: [ReadState<[String]>] = [.loaded(held), .refreshing(held)]
    for state in fromSomething {
      let started = state.whileReading
      #expect(started.isReading)
      #expect(started.held == ["one", "two"], "a pull-to-refresh cleared the list running it")
      #expect(started.hasRead, "a refresh made a read surface unread again")
    }
  }

  @Test("An empty page is empty and a page with something in it is loaded")
  func anEmptyPageIsEmptyAndAPageIsLoaded() {
    let none = ReadState<[String]>(page: [])
    #expect(none.hasRead)
    #expect(none.held.isEmpty)
    #expect(none.failure == nil)
    #expect(none.isReading == false)

    let some = ReadState<[String]>(page: ["one"])
    #expect(some.held == ["one"])
    #expect(some.hasRead)
    #expect(some.isReading == false)
  }

  @Test("Appending carries what was already held, from every state it can be appended to")
  func appendingCarriesWhatWasAlreadyHeld() {
    let held: [ReadState<[String]>] = [.loaded(["one"]), .refreshing(["one"])]
    for state in held {
      #expect(state.appending(["two"]).held == ["one", "two"], "a page landed on top of the last")
    }

    // Nothing held means the page is the whole of it. A store never pages from these, but the
    // value has to say something for each of them and "the page" is the only honest answer.
    let empty: [ReadState<[String]>] = [
      .unread,
      .reading,
      .failed(URLError(.timedOut)),
      .empty,
    ]
    for state in empty {
      #expect(state.held.isEmpty)
      #expect(state.appending(["two"]).held == ["two"])
    }

    // A page of nothing onto nothing is the empty surface, not a loaded one holding no rows.
    let none: ReadState<[String]> = ReadState(page: [])
    #expect(none.appending([]).held.isEmpty)
    #expect(none.appending([]).hasRead)
  }

  @Test("Both states that hold something answer for it, not only the settled one")
  func contentAnswersFromBothStatesThatHoldSomething() {
    // A store that reads only `loaded` refuses every write made during a refresh, and refuses it
    // without saying anything — the two states draw the same screen, so the control was there.
    #expect(ReadState<String>.loaded("one").content == "one")
    #expect(ReadState<String>.refreshing("one").content == "one")

    let nothing: [ReadState<String>] = [.unread, .reading, .failed(URLError(.timedOut)), .empty]
    for state in nothing {
      #expect(state.content == nil)
    }
  }

  @Test("A write answering during a refresh does not end the refresh")
  func aWriteAnsweringDuringARefreshDoesNotEndTheRefresh() {
    // A write can answer while a read is still suspended. Landing it as `loaded` clears the mark
    // that says a read is running, and the next thing to ask for one starts a second over the top
    // of the first.
    let running: [ReadState<String>] = [.reading, .refreshing("one")]
    for state in running {
      let after = state.holding("written")
      #expect(after.content == "written")
      #expect(after.isReading, "a write's answer reported the read that is still running as done")
    }

    let settled: [ReadState<String>] = [
      .unread,
      .failed(URLError(.timedOut)),
      .empty,
      .loaded("one"),
    ]
    for state in settled {
      let after = state.holding("written")
      #expect(after.content == "written")
      #expect(after.isReading == false, "a write's answer claimed a read nobody started")
    }
  }

  @Test("A server saying it is gone is an answer, not a failure")
  func aServerSayingItIsGoneIsNotAFailure() {
    var gone = DRApiError()
    gone.code = .notFound
    gone.message = "request 42 not found in tenant 7"

    let answered = ReadState<DRFeatureRequest>(readFailure: DifferentRequestsError.api(gone))
    #expect(answered.hasRead)
    #expect(
      answered.failure == nil,
      "a gone request offering Try Again is a button that cannot work"
    )

    var refused = DRApiError()
    refused.code = .planRequired
    let broken = ReadState<DRFeatureRequest>(readFailure: DifferentRequestsError.api(refused))
    #expect(broken.failure != nil)

    let offline = ReadState<DRFeatureRequest>(readFailure: URLError(.notConnectedToInternet))
    #expect(offline.failure != nil, "an unreachable server is not a request that has gone")
  }

  @Test("Every error code that is not notFound is a failure, read from the contract's own table")
  func everyOtherCodeIsAFailure() {
    // Read from the generated table rather than a list written here, so a code added to the
    // contract is covered by being declared.
    for code in DRErrorCode.allCases where code != .notFound {
      var answered = DRApiError()
      answered.code = code
      let state = ReadState<DRFeatureRequest>(readFailure: DifferentRequestsError.api(answered))
      #expect(
        state.failure != nil,
        "\(code) is being read as an answer rather than as a failure"
      )
    }
  }

  @Test("A write's answer replaces the row it names, and a row that has gone is left gone")
  func replacingFindsTheRowByIdAndLeavesAGoneRowGone() {
    let board: ReadState<[DRFeatureRequest]> = .loaded([
      request(id: "r1", title: "Dark mode"),
      request(id: "r2", title: "Offline drafts"),
    ])

    let written = request(id: "r2", title: "Offline drafts, as the server now holds it")
    let after = board.replacing(written, identifiedBy: { $0.id })
    #expect(after.held.count == 2)
    #expect(after.held[0].id == "r1", "the row before the written one moved")
    #expect(after.held[1].title == "Offline drafts, as the server now holds it")

    // A reload can replace the whole list while a write is suspended. The write landed either
    // way, and the next page the row appears in will say so.
    let elsewhere = request(id: "r9", title: "Something on another page")
    let untouched = board.replacing(elsewhere, identifiedBy: { $0.id })
    #expect(untouched.held.count == 2)
    #expect(untouched.held.contains(where: { $0.id == "r9" }) == false)
  }
}
