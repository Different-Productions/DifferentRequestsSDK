import Testing
@testable import DifferentRequests

@Suite("PushNotifications authorization")
struct PushNotificationsTests {

  private struct AuthorizationFailure: Error {}

  @Test("a granted request returns true")
  func grantedReturnsTrue() async throws {
    let granted = try await PushNotifications.requestAuthorization { true }
    #expect(granted)
  }

  @Test("a denied request returns false rather than throwing")
  func deniedReturnsFalse() async throws {
    let granted = try await PushNotifications.requestAuthorization { false }
    #expect(!granted)
  }

  @Test("a failed request propagates the error instead of collapsing to false")
  func failurePropagates() async {
    await #expect(throws: AuthorizationFailure.self) {
      try await PushNotifications.requestAuthorization { throw AuthorizationFailure() }
    }
  }
}
