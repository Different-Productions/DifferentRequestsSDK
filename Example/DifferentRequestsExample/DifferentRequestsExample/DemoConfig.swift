import DifferentRequests
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

  /// Points the example at a staging endpoint instead of production.
  ///
  /// Set alongside the key when the app being demonstrated lives in development. Unset — which is
  /// the normal case — the client uses the production URL baked into the SDK.
  static let baseURLEnvironmentVariable = "DIFFERENT_REQUESTS_BASE_URL"

  /// The staging endpoint to use, if one was named, is a URL, and is https.
  ///
  /// A named endpoint that is not https is refused here rather than dialled: every call carries the
  /// app key, and over plain http it would cross the wire in the clear while appearing to work.
  static var baseURL: SecureBaseURL? {
    let environment = ProcessInfo.processInfo.environment
    guard let stated = environment[baseURLEnvironmentVariable], stated.isEmpty == false else {
      return nil
    }
    guard let url = URL(string: stated) else {
      preconditionFailure(
        "\(baseURLEnvironmentVariable) is not a URL: \(stated)"
      )
    }
    do {
      return try SecureBaseURL(url)
    } catch {
      // Not defaulted back to production. Somebody who named a staging endpoint and silently got
      // production would be reading the wrong board and believing it was theirs, which is worse
      // than stopping.
      preconditionFailure(
        "\(baseURLEnvironmentVariable) must be https, and is: \(stated)"
      )
    }
  }

  /// The client this example runs on: production unless a staging endpoint was named.
  static var client: DifferentRequestsClient {
    if let baseURL {
      return .make(appKey: appKey, baseURL: baseURL)
    }
    return .make(appKey: appKey)
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
