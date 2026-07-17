import Foundation
import UIKit
import DifferentRequests

/// Owns the SDK client and the app's sign-in lifecycle.
///
/// Authenticates the demo user on `start()`, then requests push authorization
/// and (if granted) asks the system to register for remote notifications. The
/// raw APNs token arrives on the app delegate and is forwarded back here via
/// `registerDevice(tokenData:)`.
@Observable
@MainActor
final class Session {
  /// Where the app is in the sign-in flow.
  enum Phase {
    case authenticating
    case ready(User)
    case failed(String)
  }

  private(set) var phase: Phase = .authenticating

  /// The single client every screen shares.
  let client: DifferentRequestsClient

  init(client: DifferentRequestsClient) {
    self.client = client
  }

  /// Authenticate the demo user, then set up push notifications. Safe to call
  /// again to retry after a failure.
  func start() async {
    phase = .authenticating
    do {
      let user = try await client.authenticate(
        externalUserId: DemoConfig.externalUserId,
        displayName: DemoConfig.displayName,
        avatarUrl: nil,
        email: nil,
        traits: DemoConfig.traits
      )
      phase = .ready(user)
      await requestPushAuthorization()
    } catch {
      phase = .failed(error.localizedDescription)
    }
  }

  /// Ask for push permission, keeping denial (a normal `false`) distinct from
  /// a request that could not complete (a thrown error).
  private func requestPushAuthorization() async {
    do {
      let granted = try await PushNotifications.requestPushAuthorization()
      if granted {
        UIApplication.shared.registerForRemoteNotifications()
      }
    } catch {
      NSLog("Push authorization request failed: %@", error.localizedDescription)
    }
  }

  /// Forward the raw APNs device token from the app delegate to the backend.
  func registerDevice(tokenData: Data) async {
    do {
      let device = try await client.registerDevice(tokenData: tokenData)
      NSLog("Registered device token hash %@", device.tokenHash)
    } catch {
      NSLog("Device registration failed: %@", error.localizedDescription)
    }
  }
}
