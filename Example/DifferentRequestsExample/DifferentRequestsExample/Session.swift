import DifferentRequests
import Foundation
import UserNotifications
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Owns the SDK client and the app's sign-in lifecycle.
///
/// Creates a session for the demo person on `start()`, then, where notifications are already
/// allowed, registers for remote notifications. The raw APNs token arrives on the app delegate and
/// comes back here through ``registerDevice(tokenData:)``.
///
/// The SDK asks for permission itself, with its "Get notified when this request changes?" card
/// after a person's first vote or follow, so this never prompts.
@Observable
@MainActor
final class Session {

  // MARK: - Inputs

  /// What every SDK screen in this app reads from, and what holds their state between redraws. Its
  /// client is the one the screens call through, so a session created here is the session they act
  /// under.
  let hub: DifferentRequestsHub

  /// What signs a proof for the person being signed in, standing in for a developer's own backend.
  let backend: DemoBackend

  /// What the environment said at launch: the person to sign in as and where tokens are minted.
  let settings: DemoSettings

  // MARK: - State

  /// Where launch has got to, the rows it offers, and the screen that is up.
  ///
  /// The badge is not held here: it is the hub's `unreadCount()`, the same count the SDK's Inbox
  /// tab draws. What is up is one value, so two screens cannot both be.
  private(set) var state = SessionState()

  // MARK: - Init

  init(hub: DifferentRequestsHub, backend: DemoBackend, settings: DemoSettings) {
    self.hub = hub
    self.backend = backend
    self.settings = settings
  }

  // MARK: - Signing in

  /// Signs the person in, reads what the app offers, then sets up push where the app's plan sends
  /// it. Safe to call again to retry.
  ///
  /// Config is fetched here rather than by each screen because it decides which screens exist at
  /// all: the roadmap and the changelog are Pro surfaces, and a tab that is shown and then refused
  /// has told the person using the app that something is broken.
  ///
  /// Push permission is asked for only when `pushEnabled`: on a plan that sends no push, asking
  /// the person is asking for something that never arrives.
  func start() async {
    if settings.appKeySupplied {
      enter(.reading(LaunchReading()))
      await signIn()
      await loadConfig()
    } else {
      enter(.unconfigured(LaunchUnconfigured()))
    }
  }

  /// Moves launch to `phase`, and offers the rows every surface it carries.
  ///
  /// A Free app has no roadmap and no changelog, so those rows are absent rather than present and
  /// refused when tapped — the same rule the SDK's own menu follows.
  private func enter(_ phase: LaunchPhase.OneOf_Phase) {
    state.phase.phase = phase
    state.screens = ExampleScreen.allCases.filter { screen in
      screen.isCarried(in: state.phase)
    }
  }

  /// Reads the app's configuration, then the badge and the board's first page once it is known.
  ///
  /// `hub.configure()` comes first so every SDK screen draws its tabs, badge and color on its first
  /// frame. The client answers the `config()` after it from that same read.
  private func loadConfig() async {
    await hub.configure()
    do {
      let configured = try await hub.client.config()
      enter(.ready(configured.config))
      if configured.config.pushEnabled {
        await registerForRemoteNotifications()
      }
      await hub.loadInbox()
      // The board's first page is a round trip. Started here, while the person is still looking at
      // the settings list, it is held by the time they open the board.
      await hub.readTheBoardBeforeItIsShown()
    } catch {
      NSLog("What this app offers could not be read: %@", error.localizedDescription)
      enter(.configUnreadable(LaunchConfigUnreadable()))
    }
  }

  /// Creates the session for the demo person, carrying a proof when this app has a signing secret.
  ///
  /// A refusal is written where a developer reads it and drawn nowhere. The reasons are all the
  /// integration's, and none of them is something the person holding the phone can act on.
  private func signIn() async {
    do {
      let signedIn = try await hub.client.createSession(
        externalID: settings.externalUserID,
        email: nil,
        displayName: settings.displayName,
        proof: backend.vouchFor(externalID: settings.externalUserID)
      )
      NSLog("Signed in as %@", signedIn.user.id)
    } catch {
      NSLog("Sign-in refused: %@", error.localizedDescription)
    }
  }

  // MARK: - What the screens say

  /// The count on `screen`'s row: the hub's unread count on the inbox, and nothing on the others.
  func badgeCount(for screen: ExampleScreen) -> Int32 {
    switch screen {
    case .inbox:
      return hub.unreadCount()
    case .requests, .roadmap, .changelog, .diagnostics, .unspecified, .UNRECOGNIZED:
      return 0
    }
  }

  // MARK: - Which screen is up

  func show(_ screen: ExampleScreen) {
    state.showing = screen
  }

  /// Whether `screen` is the one up.
  func isShowing(_ screen: ExampleScreen) -> Bool {
    state.showing == screen
  }

  /// Whether any screen is up.
  func isShowingAny() -> Bool {
    switch state.showing {
    case .requests, .inbox, .roadmap, .changelog, .diagnostics:
      return true
    case .unspecified, .UNRECOGNIZED:
      return false
    }
  }

  /// Called when the presented screen goes away.
  func screenDismissed() {
    state.showing = .unspecified
  }

  /// Registers for remote notifications when the person already allowed them, so a rotated token
  /// reaches the server on every launch.
  private func registerForRemoteNotifications() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    if settings.authorizationStatus == .authorized {
      #if os(iOS)
      UIApplication.shared.registerForRemoteNotifications()
      #else
      NSApplication.shared.registerForRemoteNotifications()
      #endif
    }
  }

  /// Forwards the raw APNs token from the app delegate to the API.
  ///
  /// Called on every launch, not only the first: a token rotates on reinstall and Apple can
  /// invalidate one silently, so registration is an upsert rather than a one-time write.
  func registerDevice(tokenData: Data) async {
    do {
      let registered = try await hub.client.registerDevice(
        tokenData: tokenData,
        environment: settings.pushEnvironment
      )
      NSLog("Registered device %@", registered.device.id)
    } catch {
      NSLog("Device registration failed: %@", error.localizedDescription)
    }
  }
}
