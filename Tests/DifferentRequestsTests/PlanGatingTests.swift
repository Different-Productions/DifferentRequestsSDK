import DifferentRequestsProtos
import Foundation
import Testing

@testable import DifferentRequests

/// A surface the tenant's plan does not include is not a failure and not an empty surface. It is a
/// screen that says what is there instead — and the one thing it may never say is why, because the
/// contract writes `planRequired` for the host developer and the person looking at the screen
/// neither chose the plan nor can change it.
///
/// These walk the two values that decide it, and the stores that read them: that the flags are read
/// from one place, that a surface the app lacks is never asked for, and that not knowing yet is
/// never mistaken for knowing.
///
/// Hermetic, and not by pretending. A base URL whose scheme `URLSession` cannot open fails inside
/// `URLSession.data(for:)` without a lookup and without a connection, which reaches the failure
/// branch of `GetConfig` — an `APP_KEY` rpc, so the audience gate does not stand in for it.
@MainActor
struct PlanGatingTests {

  // MARK: - Fixtures

  private func nowhere() throws -> DifferentRequestsClient {
    let base = try #require(URL(string: "differentrequests-nowhere://api.invalid"))
    return .make(appKey: "test-app-key", baseURL: base)
  }

  private func config(roadmap: Bool, changelog: Bool, comments: Bool) -> DRGetConfigResponse {
    var app = DRAppConfig()
    app.roadmapEnabled = roadmap
    app.changelogEnabled = changelog
    app.commentsEnabled = comments

    var answer = DRGetConfigResponse()
    answer.config = app
    return answer
  }

  // MARK: - What a reader is told

  @Test("Every surface says what is there instead, and no two of them say the same thing")
  func everySurfaceSaysWhatIsThereInstead() {
    // Walked from the case list rather than a list written here, so a gated surface added to the
    // enum is covered by being declared instead of by anyone remembering to add it.
    var titles: Set<String> = []
    var descriptions: Set<String> = []

    for surface in PlanSurface.allCases {
      #expect(surface.absentTitle.isEmpty == false, "\(surface) is absent in silence")
      #expect(surface.absentDescription.isEmpty == false, "\(surface) says nothing about what is")
      #expect(surface.absentSymbol.isEmpty == false, "\(surface) has a Label with no image")

      #expect(
        titles.contains(surface.absentTitle) == false,
        "\(surface) is headed the same as another surface, so a reader cannot tell them apart"
      )
      #expect(
        descriptions.contains(surface.absentDescription) == false,
        "\(surface) points somewhere another surface already points"
      )

      titles.insert(surface.absentTitle)
      descriptions.insert(surface.absentDescription)
    }

    #expect(titles.count == PlanSurface.allCases.count)
    #expect(descriptions.count == PlanSurface.allCases.count)
  }

  @Test("Nothing a reader is shown mentions a plan, because a plan is not theirs to act on")
  func nothingSaidToAReaderMentionsAPlan() {
    // The contract: planRequired is "distinct from PermissionDenied because the remedy is a
    // purchase, not a different account, and only the host developer can act on it — never
    // surfaced to an end user."
    let notTheirs = ["plan", "pro", "free", "tier", "upgrade", "subscri", "price", "billing"]

    for surface in PlanSurface.allCases {
      let said = "\(surface.absentTitle) \(surface.absentDescription)".lowercased()
      for word in notTheirs {
        #expect(
          said.contains(word) == false,
          "\(surface) tells a reader about \"\(word)\", which is the host developer's to act on"
        )
      }
    }
  }

  // MARK: - What the config says

  @Test("Each surface reads its own flag")
  func eachSurfaceReadsItsOwnFlag() {
    // One flag on at a time, checked against every case: the copy-paste that returns the
    // neighbouring field fails here rather than by hiding a surface a tenant is paying for.
    let onlyRoadmap = config(roadmap: true, changelog: false, comments: false)
    let onlyChangelog = config(roadmap: false, changelog: true, comments: false)
    let onlyComments = config(roadmap: false, changelog: false, comments: true)

    for surface in PlanSurface.allCases {
      #expect(
        surface.isIncluded(in: onlyRoadmap.config) == (surface == .roadmap),
        "\(surface) reads roadmapEnabled when it should not"
      )
      #expect(
        surface.isIncluded(in: onlyChangelog.config) == (surface == .changelog),
        "\(surface) reads changelogEnabled when it should not"
      )
      #expect(
        surface.isIncluded(in: onlyComments.config) == (surface == .comments),
        "\(surface) reads commentsEnabled when it should not"
      )
    }
  }

  @Test("A config that says nothing includes nothing")
  func aConfigThatSaysNothingIncludesNothing() {
    let nothing = config(roadmap: false, changelog: false, comments: false)
    let everything = config(roadmap: true, changelog: true, comments: true)

    for surface in PlanSurface.allCases {
      #expect(PlanState(surface: surface, response: nothing).isIncluded == false)
      #expect(PlanState(surface: surface, response: everything).isIncluded)
    }
  }

  @Test("A response with no config in it is a failure rather than an answer")
  func aResponseWithNoConfigIsAFailureRatherThanAnAnswer() {
    // Every flag on an absent message reads as false, so a server that said nothing would
    // otherwise be read as a tenant who bought nothing — the same defect as rendering a surface
    // nobody asked about, arrived at from the other side.
    let silent = DRGetConfigResponse()
    #expect(silent.hasConfig == false)

    for surface in PlanSurface.allCases {
      let state = PlanState(surface: surface, response: silent)
      #expect(state.isIncluded == false)

      let carried = state.failure as? DifferentRequestsError
      if case .some(.incompleteResponse(let rpc)) = carried {
        #expect(rpc == .getConfig)
      } else {
        Issue.record("\(surface) read a response carrying no config as an answer about \(surface)")
      }
    }
  }

  // MARK: - How far the asking got

  @Test("An answered plan is not asked again, and one that failed is")
  func anAnsweredPlanIsNotAskedAgainAndAFailedOneIs() {
    #expect(PlanState.unread.needsReading, "a surface that never asked would never ask")
    #expect(
      PlanState.failed(URLError(.notConnectedToInternet)).needsReading,
      "one dropped connection closed a surface for the rest of the launch"
    )
    #expect(PlanState.reading.needsReading == false, "a read in flight was started twice")
    #expect(PlanState.included.needsReading == false, "an answer was asked for again")
    #expect(PlanState.excluded.needsReading == false, "an answer was asked for again")
  }

  @Test("Only a surface the app has is read")
  func onlyAnIncludedSurfaceIsRead() {
    #expect(PlanState.included.isIncluded)
    #expect(PlanState.excluded.isIncluded == false)
    #expect(PlanState.unread.isIncluded == false, "a read was started on a plan nobody had asked")
    #expect(PlanState.reading.isIncluded == false, "a read was started while the plan was in flight")
    #expect(
      PlanState.failed(URLError(.timedOut)).isIncluded == false,
      "a plan nobody could read was taken as one that includes everything"
    )

    #expect(PlanState.included.failure == nil)
    #expect(PlanState.excluded.failure == nil)
    #expect(PlanState.failed(URLError(.timedOut)).failure != nil)
  }

  // MARK: - The Pro surfaces

  @Test("A roadmap is not read until the app says it has one")
  func aRoadmapIsNotReadUntilTheAppSaysItHasOne() async throws {
    // GetRoadmap is one of exactly two rpcs the server refuses on plan. This is the whole fix:
    // the call that answered planRequired is not made.
    let store = RoadmapStore(client: try nowhere())
    store.plan = .excluded

    await store.load()

    #expect(store.read.hasRead == false, "a roadmap the app does not have was asked for anyway")
    #expect(
      store.plan.failure == nil,
      "an answered plan was asked again, and the ask reached the network"
    )
    #expect(store.plan.isIncluded == false)
  }

  @Test("A changelog is not read until the app says it publishes one")
  func aChangelogIsNotReadUntilTheAppSaysItPublishesOne() async throws {
    let store = ChangelogStore(client: try nowhere())
    store.plan = .excluded

    await store.load()

    #expect(store.read.hasRead == false, "release notes the app does not publish were asked for")
    #expect(store.page.failure == nil, "a surface the app does not have asked for a second page")
    #expect(store.plan.failure == nil, "an answered plan was asked again")
  }

  @Test("A plan that could not be read reads nothing and says so")
  func aPlanThatCouldNotBeReadReadsNothingAndSaysSo() async throws {
    let client = try nowhere()

    let roadmap = RoadmapStore(client: client)
    await roadmap.load()
    #expect(roadmap.plan.failure != nil, "a config read that failed said nothing")
    #expect(
      roadmap.read.hasRead == false,
      "the roadmap was read before anyone knew whether the app has one"
    )

    let changelog = ChangelogStore(client: client)
    await changelog.load()
    #expect(changelog.plan.failure != nil)
    #expect(changelog.read.hasRead == false)
  }

  @Test("A surface the app has is read")
  func aSurfaceTheAppHasIsRead() async throws {
    // The gate opens as well as closing. Seeded rather than fetched, because a real answer needs a
    // server; what happens after it is what this walks.
    let client = try nowhere()

    let roadmap = RoadmapStore(client: client)
    roadmap.plan = .included
    await roadmap.load()
    #expect(roadmap.read.failure != nil, "an included roadmap was never read")
    #expect(roadmap.read.hasRead, "a failed read that stays unread makes .firstRead read forever")

    let changelog = ChangelogStore(client: client)
    changelog.plan = .included
    await changelog.load()
    #expect(changelog.read.failure != nil)
    #expect(changelog.page.isDone, "a failed changelog still offering another page spins under it")
  }

  // MARK: - The composer

  @Test("A request that cannot be read does not ask about comments")
  func aRequestThatCannotBeReadDoesNotAskAboutComments() async throws {
    let store = RequestDetailStore(client: try nowhere(), requestID: "r1")

    await store.load()

    #expect(store.read.failure != nil)
    #expect(
      store.commenting.failure == nil,
      "a request nobody could read reported a second failure about answering it"
    )
    #expect(store.commenting.isIncluded == false)
    #expect(store.commenting.needsReading, "the question was settled without being asked")
  }

  @Test("A composer asks again after a config read that failed")
  func aComposerAsksAgainAfterAConfigReadThatFailed() async throws {
    // The Try Again in the composer's strip has to be a retry rather than a no-op.
    let store = RequestDetailStore(client: try nowhere(), requestID: "r1")

    await store.loadCommenting()
    #expect(store.commenting.failure != nil)
    #expect(store.commenting.needsReading, "one outage closed the composer for the rest of the run")

    await store.loadCommenting()
    #expect(store.commenting.failure != nil, "the retry did not ask")
  }

  @Test("A settled answer about comments is not asked again")
  func aSettledCommentingAnswerIsNotAskedAgain() async throws {
    let store = RequestDetailStore(client: try nowhere(), requestID: "r1")
    store.commenting = .excluded

    await store.loadCommenting()

    #expect(store.commenting.failure == nil, "an answered question was asked again over the network")
    #expect(store.commenting.isIncluded == false)
  }
}
