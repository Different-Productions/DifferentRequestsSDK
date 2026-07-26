import DifferentRequests
import Foundation
import UIKit
import UserNotifications

/// Owns the SDK client and the app's sign-in lifecycle.
///
/// Creates a session for the demo person on `start()`, then asks for push permission and, if it is
/// granted, registers for remote notifications. The raw APNs token arrives on the app delegate and
/// comes back here through ``registerDevice(tokenData:)``.
///
/// Permission is asked for here rather than by the SDK. A host app decides when to prompt — usually
/// after showing why — and a package that prompts on its own behalf takes that decision away.
@Observable
@MainActor
final class Session {

  /// Where the app is in the sign-in flow.
  enum Phase {
    /// No app key was supplied, so there is nothing to sign in to.
    case unconfigured
    case creatingSession
    case ready(DREndUser)
    case failed(String)
  }

  // MARK: - Inputs

  /// The single client every screen shares.
  let client: DifferentRequestsClient

  // MARK: - State

  var phase: Phase = .creatingSession

  // MARK: - Init

  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Signing in

  /// Creates the session, then sets up push. Safe to call again to retry after a failure.
  func start() async {
    if DemoConfig.isConfigured == false {
      phase = .unconfigured
      return
    }

    phase = .creatingSession
    do {
      let session = try await client.createSession(
        externalID: DemoConfig.externalUserID,
        email: nil,
        displayName: DemoConfig.displayName,
        traits: DemoConfig.traits
      )
      phase = .ready(session.user)
      await requestPushAuthorization()
    } catch {
      phase = .failed(error.localizedDescription)
    }
  }

  /// Asks for push permission, keeping denial — a normal `false` — distinct from a request that
  /// could not complete at all.
  private func requestPushAuthorization() async {
    do {
      let granted = try await UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .badge, .sound])
      if granted {
        UIApplication.shared.registerForRemoteNotifications()
      }
    } catch {
      NSLog("Push authorization request failed: %@", error.localizedDescription)
    }
  }

  /// Forwards the raw APNs token from the app delegate to the API.
  ///
  /// Called on every launch, not only the first: a token rotates on reinstall and Apple can
  /// invalidate one silently, so registration is an upsert rather than a one-time write.
  func registerDevice(tokenData: Data) async {
    do {
      let registered = try await client.registerDevice(
        tokenData: tokenData,
        environment: DemoConfig.pushEnvironment
      )
      NSLog("Registered device %@", registered.device.id)
    } catch {
      NSLog("Device registration failed: %@", error.localizedDescription)
    }
  }
}
