import Foundation
import UserNotifications
#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// The "Get told when this changes?" card: offered after a person's first vote or follow, answered
/// once per phone, and the door to Apple's own notification prompt.
///
/// Offered only where the host app left permission to the SDK, the app's plan sends notifications,
/// and Apple has not been asked yet. The device token Apple hands back reaches the host app's
/// delegate, which registers it through
/// ``DifferentRequestsClient/registerDevice(tokenData:environment:)`` as before.
@MainActor
@Observable
final class NotificationOffer {

  /// The `UserDefaults` key that remembers the card was answered on this phone.
  private static let answeredKey = "DifferentRequests.notificationOfferAnswered"

  // MARK: - Inputs

  /// Who asks for notification permission, as the host app set it.
  let permission: NotificationPermission

  /// Whether this app's plan sends notifications at all.
  let appConfig: AppConfigStore

  /// Where "answered" is remembered, so the card is never offered twice on one phone.
  let defaults: UserDefaults

  // MARK: - State

  /// Where the card is.
  private(set) var state: NotificationOfferState = .hidden

  // MARK: - Init

  /// - Parameters:
  ///   - permission: Who asks for notification permission.
  ///   - appConfig: Whether this app's plan sends notifications.
  ///   - defaults: Where the card's answer is remembered.
  init(permission: NotificationPermission, appConfig: AppConfigStore, defaults: UserDefaults) {
    self.permission = permission
    self.appConfig = appConfig
    self.defaults = defaults
  }

  // MARK: - Offering

  /// Whether the card is drawn under `requestID`.
  func isOffered(on requestID: String) -> Bool {
    state.requestID == requestID
  }

  /// Offers the card under `requestID` after a vote or follow landed there, when the host app left
  /// permission to the SDK, it has never been answered on this phone, the plan sends notifications,
  /// and Apple has not been asked yet.
  func votedOrFollowed(requestID: String) async {
    if permission == .askedBySDK,
      state.requestID == nil,
      appConfig.config.pushEnabled,
      defaults.bool(forKey: Self.answeredKey) == false {
      let settings = await UNUserNotificationCenter.current().notificationSettings()
      if settings.authorizationStatus == .notDetermined {
        state = .offered(requestID: requestID)
      }
    }
  }

  // MARK: - Answering

  /// "Not now": the card goes, and is not offered again on this phone.
  func decline() {
    defaults.set(true, forKey: Self.answeredKey)
    state = .hidden
  }

  /// "Turn on": the card goes, Apple's prompt comes up, and a yes registers for remote
  /// notifications so the token reaches the host app's delegate.
  func accept() async {
    if let requestID = state.requestID {
      defaults.set(true, forKey: Self.answeredKey)
      state = .hidden

      do {
        let granted = try await UNUserNotificationCenter.current()
          .requestAuthorization(options: [.alert, .badge, .sound])
        if granted {
          registerForRemoteNotifications()
        }
      } catch {
        state = .failed(NotificationOfferFailure(requestID: requestID, error: error))
      }
    }
  }

  /// Asks the platform for a device token, which arrives on the host app's delegate.
  private func registerForRemoteNotifications() {
    #if canImport(UIKit)
      UIApplication.shared.registerForRemoteNotifications()
    #elseif canImport(AppKit)
      NSApplication.shared.registerForRemoteNotifications()
    #endif
  }
}
