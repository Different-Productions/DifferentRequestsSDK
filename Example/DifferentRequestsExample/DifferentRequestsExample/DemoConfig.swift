import Foundation

/// Static configuration for the example app.
///
/// The API key is read from the `DIFFERENT_REQUESTS_API_KEY` environment
/// variable so a real key never has to live in source. Set it in the scheme's
/// Run > Arguments > Environment Variables to talk to a real app; when it is
/// absent the app uses an obviously-fake placeholder so the project still
/// builds and launches without a committed key.
enum DemoConfig {
  /// Name of the environment variable that carries a real API key at run time.
  private static let apiKeyEnvironmentVariable = "DIFFERENT_REQUESTS_API_KEY"

  /// Obviously-fake stand-in used when no key is provided. Never replace this
  /// with a real key — supply one through the environment variable instead.
  private static let placeholderAPIKey = "YOUR_API_KEY"

  /// The API key the client is initialized with.
  static var apiKey: String {
    let environment = ProcessInfo.processInfo.environment
    if let key = environment[apiKeyEnvironmentVariable], !key.isEmpty {
      return key
    }
    return placeholderAPIKey
  }

  /// Your app's stable identifier for the signed-in user.
  static let externalUserId = "demo-user"

  /// The user's display name, shown on requests and comments they author.
  static let displayName = "Demo User"

  /// Segmentation attributes forwarded to the backend at authentication time.
  static let traits: [String: String] = ["platform": "ios", "tier": "demo"]
}
