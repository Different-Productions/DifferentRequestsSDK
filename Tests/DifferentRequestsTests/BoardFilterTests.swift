import DifferentRequestsProtos
import Foundation
import Testing

@testable import DifferentRequests

/// What the board's filter bar offers, what tapping it does to the store, and what an empty board
/// says about why it is empty.
///
/// Hermetic, and not by pretending. A base URL whose scheme `URLSession` cannot open fails inside
/// `URLSession.data(for:)` without a lookup and without a connection, so every `load()` here is a
/// real trip through the store's state machine that ends in a failure. What is asserted is what was
/// asked and what the store did with it, which is the half a server has no say in.
///
/// Nothing below names a status or a ranking of its own. Both strips come from the contract's
/// generated tables, so a value added to the contract is covered here by being declared rather than
/// by being remembered.
@MainActor
struct BoardFilterTests {

  private func nowhere() throws -> DifferentRequestsClient {
    let base = try #require(URL(string: "differentrequests-nowhere://api.invalid"))
    return .make(appKey: "test-app-key", baseURL: base)
  }

  private func board() throws -> BoardStore {
    BoardStore(client: try nowhere(), statuses: [], sort: .top)
  }

  private func request(id: String) -> DRFeatureRequest {
    var made = DRFeatureRequest()
    made.id = id
    made.title = "Dark mode everywhere"
    return made
  }

  // MARK: - What the bar offers

  @Test("The bar offers exactly the values the contract can spell, in both directions")
  func theBarOffersExactlyWhatTheContractCanSend() throws {
    let store = try board()

    for sort in DRRequestSort.allCases {
      #expect(
        store.offeredSorts.contains(sort) == (sort.urlToken != nil),
        "ranking \(sort.rawValue) is offered on some ground other than whether it can be sent"
      )
    }
    for offered in store.offeredSorts {
      #expect(offered.urlToken != nil, "a ranking with no spelling in a URL reached the bar")
    }

    for status in DRRequestStatus.allCases {
      #expect(
        store.offeredStatuses.contains(status) == (status.urlToken != nil),
        "status \(status.rawValue) is offered on some ground other than whether it can be sent"
      )
    }
    for offered in store.offeredStatuses {
      #expect(offered.urlToken != nil, "a status with no spelling in a URL reached the bar")
    }
  }

  @Test("The zero every proto enum decodes to by default is on neither strip")
  func theZeroSentinelIsNeverOffered() throws {
    let store = try board()

    // The whole reason the strips are filtered by `urlToken` rather than by `allCases` alone: this
    // value is what an unset field decodes to, and offering it would put a `0` in a query string.
    #expect(DRRequestSort.unspecified.rawValue == 0)
    #expect(DRRequestStatus.unspecified.rawValue == 0)
    #expect(DRRequestSort.unspecified.urlToken == nil)
    #expect(DRRequestStatus.unspecified.urlToken == nil)

    #expect(store.offeredSorts.contains(.unspecified) == false)
    #expect(store.offeredStatuses.contains(.unspecified) == false)
  }

  // MARK: - Tapping it

  @Test("A status goes on, and comes off again")
  func aStatusGoesOnAndComesOffAgain() async throws {
    let store = try board()
    let status = try #require(store.offeredStatuses.first)

    await store.toggle(status: status)
    #expect(store.statuses == [status])

    await store.toggle(status: status)
    #expect(store.statuses.isEmpty, "the All capsule never lights up again")
  }

  @Test("Tapped in any order, the statuses are spelled in the order the contract declares them")
  func statusesAreSpelledInTheOrderTheContractDeclaresThem() async throws {
    let store = try board()

    for status in store.offeredStatuses.reversed() {
      await store.toggle(status: status)
    }

    // The client joins these into one comma-separated query value, so two orders of one set are
    // two different URLs for one question.
    #expect(
      store.statuses == store.offeredStatuses,
      "the same set of statuses would be sent as a different URL depending on tap order"
    )
  }

  @Test("Showing every status drops the statuses and nothing else")
  func showEveryStatusLeavesTheSearchAlone() async throws {
    let store = try board()
    store.query = "dark mode"
    let status = try #require(store.offeredStatuses.first)
    await store.toggle(status: status)

    await store.showEveryStatus()

    #expect(store.statuses.isEmpty)
    #expect(
      store.query == "dark mode",
      "a control labelled for statuses took away words the reader can see in a field"
    )
  }

  @Test("Every ranking the contract declares can be asked for, and replaces the one before it")
  func showingARankingReplacesTheOneBefore() async throws {
    let store = try board()

    for sort in store.offeredSorts {
      await store.show(sort: sort)
      #expect(store.sort == sort)
      #expect(store.question.sort == sort, "the ranking on the bar is not the one being asked for")
    }
  }

  @Test("A filter change reads again rather than only setting a property")
  func aFilterChangeAsksAgainRatherThanPagingOn() async throws {
    let store = try board()
    let ranking = try #require(store.offeredSorts.first { $0 != store.sort })
    store.read = .loaded([request(id: "r1"), request(id: "r2")])
    store.page = .more

    await store.show(sort: ranking)

    #expect(store.isCurrent, "the board is still current for the ranking that was replaced")
    #expect(
      store.read.held.isEmpty,
      "a new ranking was paged onto the rows read under the old one instead of replacing them"
    )
    #expect(store.page.isDone, "a board that could not be read is still offering another page")

    let status = try #require(store.offeredStatuses.first)
    store.read = .loaded([request(id: "r3")])

    await store.toggle(status: status)

    #expect(store.isCurrent, "the board is still current for the unfiltered question")
    #expect(store.read.held.isEmpty)
  }

  // MARK: - Staleness

  @Test("A board is current for one question and for no other")
  func everyNarrowingIsCurrentOnlyForItsOwnQuestion() async throws {
    let store = try board()
    await store.load()
    #expect(store.isCurrent, "a board that has read does not answer the question it read for")

    // Each of the three moved on its own. A staleness check written per property is one that a
    // fourth property gets added past, and the symptom is a control that does nothing.
    store.query = "dark mode"
    #expect(store.isCurrent == false, "a search typed since the read is not noticed")
    store.query = ""
    #expect(store.isCurrent)

    let status = try #require(store.offeredStatuses.first)
    store.statuses = [status]
    #expect(store.isCurrent == false, "a status set since the read is not noticed")
    store.statuses = []
    #expect(store.isCurrent)

    let ranking = try #require(store.offeredSorts.first { $0 != store.sort })
    store.sort = ranking
    #expect(store.isCurrent == false, "a ranking set since the read is not noticed")
  }

  // MARK: - What an empty board says

  @Test("A question knows what it is holding back, and every case is reachable")
  func aQuestionKnowsWhatItIsHoldingBack() throws {
    let store = try board()
    let status = try #require(store.offeredStatuses.first)
    let ranking = try #require(store.offeredSorts.first)

    let expectations: [(question: BoardQuestion, narrowing: BoardNarrowing, filtered: Bool)] = [
      (BoardQuestion(statuses: [], sort: ranking, query: ""), .nothing, false),
      (BoardQuestion(statuses: [], sort: ranking, query: "dark mode"), .query, false),
      (BoardQuestion(statuses: [status], sort: ranking, query: ""), .statuses, true),
      (
        BoardQuestion(statuses: [status], sort: ranking, query: "dark mode"),
        .queryAndStatuses,
        true
      ),
    ]

    for expectation in expectations {
      let read = BoardNarrowing(question: expectation.question)
      #expect(read == expectation.narrowing)
      #expect(
        read.isStatusFiltered == expectation.filtered,
        "\(read) offers the wrong way out of an empty board"
      )
    }

    // Every case reached by some question. A case nothing produces is copy nobody can read.
    let reached = expectations.map { $0.narrowing }
    for narrowing in BoardNarrowing.allCases {
      #expect(reached.contains(narrowing), "no question produces \(narrowing)")
    }
  }

  @Test("Every narrowing says something, and no two say the same thing")
  func everyNarrowingSaysSomethingDifferent() {
    let titles = BoardNarrowing.allCases.map { $0.emptyTitle }
    let messages = BoardNarrowing.allCases.map { $0.emptyMessage }
    let footers = BoardNarrowing.allCases.map { $0.listFooter }
    let icons = BoardNarrowing.allCases.map { $0.emptyIcon }

    for text in titles + messages + footers + icons {
      #expect(text.isEmpty == false, "a narrowing with nothing to say draws a blank page")
    }

    // The icons are allowed to repeat — a search that found nothing and a filtered search that
    // found nothing are the same picture — but the words are not. Two narrowings with one sentence
    // is a branch that was never written.
    #expect(Set(titles).count == titles.count, "two narrowings share a heading")
    #expect(Set(messages).count == messages.count, "two narrowings share a sentence")
    #expect(Set(footers).count == footers.count, "two narrowings share a footer")
  }

  @Test("An empty board describes the read that emptied it, not the capsules tapped since")
  func anEmptyBoardDescribesTheReadThatEmptiedIt() async throws {
    let store = try board()
    let status = try #require(store.offeredStatuses.first)

    await store.toggle(status: status)
    #expect(store.narrowing == .statuses)

    // The capsules move with no read behind them. What the reader is looking at is still the
    // answer to the question that was actually asked, so that is what the sentence describes.
    store.statuses = []
    #expect(
      store.narrowing == .statuses,
      "the sentence under an empty board moved before the board did"
    )

    await store.load()
    #expect(store.narrowing == .nothing)
  }
}
