import Foundation

/// Errors thrown by the DifferentRequests SDK.
public enum DifferentRequestsError: Error, Sendable, LocalizedError {
  /// The operation requires an authenticated user session.
  /// Call ``DifferentRequestsClient/authenticate(externalUserId:displayName:avatarUrl:)`` first.
  case notAuthenticated

  /// The requested resource was not found.
  case notFound(message: String)

  /// The caller is authenticated but not permitted to perform this action
  /// (e.g. deleting another user's comment).
  case forbidden(message: String)

  /// The app's plan does not include this feature (e.g. the roadmap requires
  /// a Pro plan).
  case paymentRequired(message: String)

  /// The request failed validation.
  case validationError(message: String)

  /// Too many requests. Wait before retrying.
  case rateLimited(retryAfter: Int)

  /// The server returned an unexpected error.
  case serverError(statusCode: Int, message: String)

  /// A network-level error occurred.
  case networkError(underlying: any Error)

  /// The request was merged into another request.
  case merged(targetId: String)

  /// The server returned a value in a shape the SDK could not decode (e.g. an
  /// unparseable timestamp).
  case decodingError(message: String)

  public var errorDescription: String? {
    switch self {
    case .notAuthenticated:
      return "Not authenticated. Call authenticate() first."
    case .notFound(let message):
      return message
    case .forbidden(let message):
      return message
    case .paymentRequired(let message):
      return message
    case .validationError(let message):
      return message
    case .rateLimited(let retryAfter):
      return "Rate limited. Try again in \(retryAfter) seconds."
    case .serverError(let statusCode, let message):
      return "Server error (\(statusCode)): \(message)"
    case .networkError(let underlying):
      return "Network error: \(underlying.localizedDescription)"
    case .merged(let targetId):
      return "This request was merged into \(targetId)."
    case .decodingError(let message):
      return message
    }
  }
}
