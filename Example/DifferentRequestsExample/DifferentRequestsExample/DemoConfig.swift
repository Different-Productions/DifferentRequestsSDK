import Foundation

/// Static configuration for the example app.
///
/// The app key comes from an environment variable rather than from an edited constant, and the
/// reason is specific: this repository is public, and a live key was once committed in this very
/// example. A placeholder that a developer is invited to replace in a tracked file is a placeholder
/// that eventually gets committed with a real value in it.
///
/// Set it in the scheme's Run > Arguments > Environment Variables. Without it the app still builds
/// and launches, and says what to set — see ``isConfigured``.
enum DemoConfig {
  /// Carries a real app key at run time.
  static let appKeyEnvironmentVariable = "DIFFERENT_REQUESTS_APP_KEY"

  /// Obviously-fake stand-in used when no key is provided. Never replace this with a real key —
  /// supply one through the environment variable instead.
  private static let placeholderAppKey = "YOUR_APP_KEY"

  /// The key the client presents.
  static var appKey: String {
    let environment = ProcessInfo.processInfo.environment
    if let key = environment[appKeyEnvironmentVariable], key.isEmpty == false {
      return key
    }
    return placeholderAppKey
  }

  /// Whether a real key was supplied.
  ///
  /// Checked so the app can explain itself instead of showing a sign-in failure: an unset variable
  /// and a revoked key both produce a 401, and only one of them is worth a developer's time to
  /// debug.
  static var isConfigured: Bool {
    appKey != placeholderAppKey
  }

  /// Your app's own stable identifier for the signed-in person.
  ///
  /// The dedupe key: the same value on a new device is the same person, which is what carries their
  /// votes across a reinstall.
  static let externalUserID = "demo-user"

  /// Shown on requests and comments they author.
  static let displayName = "Demo User"

  /// Host-app attributes a triager sees next to a request.
  static let traits: [String: String] = ["platform": "ios", "tier": "demo"]

  /// Which APNs environment minted this build's device tokens.
  ///
  /// Stated rather than detected, because the SDK refuses a token with no environment: a sandbox
  /// token pushed to production fails per-token with no useful error, so guessing wrong makes push
  /// quietly not work for that person.
  static var pushEnvironment: DRPushEnvironment {
    #if DEBUG
    return .sandbox
    #else
    return .production
    #endif
  }
}
