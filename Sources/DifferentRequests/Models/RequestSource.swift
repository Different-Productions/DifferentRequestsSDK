import Foundation

/// Source of a feature request.
///
/// Indicates whether a request was submitted by an end user via the SDK
/// or created by the team via the console.
public enum RequestSource: String, Sendable {
  /// Submitted by an end user through the SDK.
  case sdk
  /// Created by the team through the console.
  case console
}
