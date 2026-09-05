import DifferentRequestsProtos
import Foundation
import Testing

@testable import DifferentRequests

/// Whether a free app's screens say where they came from, and — the half that matters — whether a
/// paying app's ever could.
///
/// The two mistakes are not the same size. A badge missing for a moment costs nothing. A badge on
/// an app that pays to be rid of it is a support ticket from a customer who is right, so every
/// state that is not a definite "this app is free" draws nothing.
///
/// Hermetic the same way `PlanGatingTests` is: a base URL whose scheme `URLSession` cannot open
/// fails without a lookup and without a connection.
@MainActor
struct BadgeTests {

  private func nowhere() throws -> DifferentRequestsClient {
    let base = try #require(URL(string: "differentrequests-nowhere://api.invalid"))
    return .make(appKey: "test-app-key", baseURL: base)
  }

  private func config(showBadge: Bool) -> DRGetConfigResponse {
    var app = DRAppConfig()
    app.showBadge = showBadge

    var answer = DRGetConfigResponse()
    answer.config = app
    return answer
  }

  @Test("A free app carries it")
  func aFreeAppCarriesIt() {
    #expect(BadgeState(response: config(showBadge: true)).isCarried)
  }

  @Test("An app that pays does not")
  func aPayingAppDoesNot() {
    #expect(BadgeState(response: config(showBadge: false)).isCarried == false)
  }

  /// The important one. Not knowing is not the same as knowing the answer is yes, and defaulting a
  /// failed read to "show it" would put the badge on a paying app whenever the network hiccuped.
  @Test("Nothing is drawn until the configuration has actually answered")
  func nothingIsDrawnUntilTheAnswerArrives() throws {
    let nowhere = try #require(URL(string: "differentrequests-nowhere://api.invalid"))
    let unanswered: [BadgeState] = [
      .unread,
      .reading,
      .failed(DifferentRequestsError.invalidBaseURL(nowhere))
    ]

    for state in unanswered {
      #expect(state.isCarried == false, "\(state) is not an answer, so it draws nothing")
    }
  }

  /// A failed read is worth asking again. An answered one is not — an app does not change plan
  /// mid-launch, and the client answers a repeat from its first read anyway.
  @Test("Only an unasked or failed read is asked again")
  func onlyAFailedReadIsRetried() throws {
    let nowhere = try #require(URL(string: "differentrequests-nowhere://api.invalid"))
    #expect(BadgeState.unread.needsReading)
    #expect(BadgeState.failed(DifferentRequestsError.invalidBaseURL(nowhere)).needsReading)
    #expect(BadgeState.reading.needsReading == false)
    #expect(BadgeState.carried.needsReading == false)
    #expect(BadgeState.bought.needsReading == false)
  }

  /// A configuration that never answers leaves the badge off, and leaves the store willing to ask
  /// again rather than stuck reading.
  @Test("A read that cannot reach the server draws no badge and stays retryable")
  func aFailedReadDrawsNothing() async throws {
    let store = BadgeStore(client: try nowhere())
    await store.load()

    #expect(store.state.isCarried == false)
    #expect(store.state.needsReading, "a failure has to be askable again, or it is permanent")
  }
}
