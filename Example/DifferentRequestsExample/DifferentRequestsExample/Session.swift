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

  // MARK: - Inputs

  /// What every SDK screen in this app reads from, and what holds their state between redraws.
  let hub: DifferentRequestsHub

  /// What signs a proof for the person being signed in, standing in for a developer's own backend.
  let backend: DemoBackend

  // MARK: - State

  private(set) var phase: LaunchPhase = .reading

  /// How many notifications this reader has not opened.
  ///
  /// Read through the client rather than from the SDK's own inbox store, because that store is
  /// internal — the SDK exposes screens, not the state behind them. A host app that wants a badge
  /// outside those screens asks the API for the count, which is one read and exactly what the count
  /// route exists for.
  private(set) var unreadCount = 0

  /// Which SDK screen is presented, or none.
  ///
  /// Held here rather than as a flag per screen on the view, because what is open is one fact and
  /// two booleans can both be true.
  private(set) var showing: ExampleScreen?

  // MARK: - Derived

  /// The rows this app offers, which is every surface the server says this app carries.
  ///
  /// A Free app has no roadmap and no changelog, so those rows are absent rather than present and
  /// refused when tapped — the same rule the SDK's own menu follows.
  var screens: [ExampleScreen] {
    switch phase {
    case .ready(let config):
      return ExampleScreen.allCases.filter { screen in
        screen.isCarried(by: config)
      }
    case .unconfigured, .reading, .configUnreadable:
      return []
    }
  }

  /// The client the hub was built with — the same one the screens call through, so a session
  /// created here is the session they act under.
  var client: DifferentRequestsClient {
    hub.client
  }

  // MARK: - Init

  init(hub: DifferentRequestsHub, backend: DemoBackend) {
    self.hub = hub
    self.backend = backend
  }

  // MARK: - Signing in

  /// Signs the person in, reads what the app offers, then sets up push where the app's plan sends
  /// it. Safe to call again to retry.
  ///
  /// Config is fetched here rather than by each screen because it decides which screens exist at
  /// all: the roadmap and the changelog are Pro surfaces, and a tab that is shown and then refused
  /// has told the person using the app that something is broken. Asking once, before
  /// anything is drawn, is the difference between an absent tab and a dead one.
  ///
  /// Push permission is asked for only when `pushEnabled`: on a plan that sends no push, asking
  /// the person is asking for something that never arrives.
  func start() async {
    if DemoConfig.isConfigured == false {
      phase = .unconfigured
      return
    }

    phase = .reading
    await signIn()

    do {
      let configured = try await client.config()
      phase = .ready(configured.config)
      if configured.config.pushEnabled {
        await requestPushAuthorization()
      }
    } catch {
      NSLog("What this app offers could not be read: %@", error.localizedDescription)
      phase = .configUnreadable
      return
    }

    await refreshUnreadCount()
    // The board's first page is a round trip. Started here, while the person is still looking at
    // the settings list, it is held by the time they open the board.
    await hub.readTheBoardBeforeItIsShown()
  }

  /// Creates the session for the demo person, carrying a proof when this app has a signing secret.
  ///
  /// A refusal is written where a developer reads it and drawn nowhere. The reasons are all the
  /// integration's — no proof, an expired one, a secret that has been replaced, a retired app key —
  /// and none of them is something the person holding the phone can act on. The board still reads,
  /// and asking, voting and commenting are not offered until somebody is signed in.
  private func signIn() async {
    let externalID = ProcessInfo.processInfo.demoExternalUserID
    do {
      let signedIn = try await client.createSession(
        externalID: externalID,
        email: nil,
        displayName: ProcessInfo.processInfo.demoDisplayName,
        traits: DemoConfig.traits,
        proof: backend.vouchFor(externalID: externalID)
      )
      NSLog("Signed in as %@", signedIn.user.id)
    } catch {
      NSLog("Sign-in refused: %@", error.localizedDescription)
    }
  }

  // MARK: - What the screens say

  /// Re-reads the badge.
  ///
  /// A failure leaves the count where it was and says nothing: a badge is the least important thing
  /// on screen, and an alert about one would interrupt somebody to tell them about a number they had
  /// not looked at.
  func refreshUnreadCount() async {
    do {
      unreadCount = Int(try await client.unreadCount().unreadCount)
    } catch {
      NSLog("Unread count unavailable: %@", error.localizedDescription)
    }
  }

  // MARK: - Which screen is up

  func show(_ screen: ExampleScreen) {
    showing = screen
  }

  /// Called when the presented screen goes away.
  ///
  /// The badge is re-read here rather than on a timer: the one thing that changes it is somebody
  /// reading their inbox, and they just closed it.
  func dismissedWhatWasShowing() async {
    showing = nil
    await refreshUnreadCount()
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
