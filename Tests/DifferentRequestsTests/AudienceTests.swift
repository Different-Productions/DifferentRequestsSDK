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
    static let methods: [RequestsServiceMethod] = [
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
    for method in RequestsServiceMethod.allCases {
      #expect(
        method.audience != .unspecified,
        "\(method.path) has no audience, which would leave it open to anyone with an app key"
      )
    }
  }

  @Test("Acting for a person requires a session, never a bare app key")
  func actingForAPersonRequiresASession() {
    for method in ActsForAPerson.methods {
      #expect(
        method.audience == .endUser,
        "\(method.path) writes or reads on behalf of a person and must not accept a bare app key"
      )
    }
  }

  @Test("Reading the board needs only an app key, so a host app can show it before anyone signs in")
  func readingTheBoardNeedsOnlyAnAppKey() {
    let openToAppKey: [RequestsServiceMethod] = [
      .getConfig,
      .createSession,
      .listRequests,
      .getRequest,
      .listComments,
      .getRoadmap,
      .listChangelog,
    ]

    for method in openToAppKey {
      #expect(method.audience == .appKey, "\(method.path) should be readable with an app key")
    }
  }

  @Test("The table covers the whole surface")
  func theTableCoversTheWholeSurface() {
    // Every case is either something acting for a person or something an app key may read.
    // A new rpc that is neither is a gap in these tests, not a third category.
    let accountedFor = Set(ActsForAPerson.methods.map(\.path))
    let appKeyReadable = RequestsServiceMethod.allCases
      .filter { accountedFor.contains($0.path) == false }

    for method in appKeyReadable {
      #expect(method.audience == .appKey, "\(method.path) is not covered by either audience")
    }
  }
}
