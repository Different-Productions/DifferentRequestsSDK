import DifferentRequestsProtos
import Testing
@testable import DifferentRequests

/// The audience on an rpc is what stops a bare app key from acting as a person: an app key
/// identifies the tenant's app but nobody inside it, so an rpc that writes on someone's behalf
/// must require a session. The generated table is where that lives, and a new rpc joins it by
/// being declared rather than by anyone remembering to gate it — so these read the table
/// itself rather than the client's behaviour.
struct AudienceTests {

  /// Every rpc that acts for a person, named here so that adding one to the contract without
  /// gating it fails a test instead of shipping.
  private enum ActsForAPerson {
    static let methods: [DRRequestsServiceRPC] = [
      .createRequest,
      .vote,
      .clearVote,
      .follow,
      .unfollow,
      .createComment,
      .listNotifications,
      .getUnreadCount,
      .markNotificationRead,
      .markAllNotificationsRead,
      .registerDevice,
      .unregisterDevice,
    ]
  }

  @Test("Every rpc declares an audience")
  func everyRPCDeclaresAnAudience() {
    for method in DRRequestsServiceRPC.allCases {
      #expect(
        method.audience != .unspecified,
        "\(method.rawValue) has no audience, which would leave it open to anyone with an app key"
      )
    }
  }

  @Test("Acting for a person requires a session, never a bare app key")
  func actingForAPersonRequiresASession() {
    for method in ActsForAPerson.methods {
      #expect(
        method.audience == .endUser,
        "\(method.rawValue) writes or reads on behalf of a person and must not accept a bare app key"
      )
    }
  }

  @Test("Everything else needs only an app key, so a host app shows the board before anyone signs in")
  func everythingElseNeedsOnlyAnAppKey() {
    // Every case is either something acting for a person or something an app key may read. A new
    // rpc that is neither is a gap in these tests, not a third category.
    //
    // The app-key side is subtracted from the generated table rather than listed. A list of it sat
    // beside this test naming seven rpcs, and it asserted less: an rpc added to the contract and
    // gated wrongly was not on the list, so nothing looked at it. Subtracting means every rpc is
    // looked at, including the ones nobody has written down.
    let accountedFor = Set(ActsForAPerson.methods.map(\.rawValue))
    let appKeyReadable = DRRequestsServiceRPC.allCases
      .filter { accountedFor.contains($0.rawValue) == false }

    #expect(appKeyReadable.isEmpty == false, "every rpc acts for a person, so this test proves nothing")
    for method in appKeyReadable {
      #expect(method.audience == .appKey, "\(method.rawValue) is not covered by either audience")
    }
  }
}
