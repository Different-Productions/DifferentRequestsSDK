import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

// MARK: - Custom Header

// MARK: - Auth Errors

private enum AuthMiddlewareError: Error {
  case invalidHeaderName
}

/// A client for the DifferentRequests API.
///
/// Thread-safe actor that manages API key auth and user session tokens.
/// Call `authenticate` before using methods that require a user session
/// (submitting requests, voting).
public actor DifferentRequestsClient {
  private var underlyingClient: any APIProtocol
  private let apiKey: String
  private let baseURL: URL
  private var sessionToken: String?

  /// The default production API URL.
  private static let productionURL = URL(string: "https://kstb23efj8.execute-api.us-east-1.amazonaws.com")

  // MARK: - Initialization

  /// Create a client with your API key.
  ///
  /// Get your API key from the DifferentRequests console.
  /// - Parameter apiKey: Your app's API key.
  public init(apiKey: String) {
    guard let url = Self.productionURL else {
      fatalError("Invalid production URL — this is a SDK bug, please report it.")
    }
    self.apiKey = apiKey
    self.baseURL = url
    self.sessionToken = nil
    self.underlyingClient = Client(
      serverURL: url,
      transport: URLSessionTransport(),
      middlewares: [AuthMiddleware(apiKey: apiKey, sessionToken: nil)]
    )
  }

  /// Create a client with an API key and custom base URL (for testing).
  package init(apiKey: String, baseURL: URL) {
    self.apiKey = apiKey
    self.baseURL = baseURL
    self.sessionToken = nil
    self.underlyingClient = Client(
      serverURL: baseURL,
      transport: URLSessionTransport(),
      middlewares: [AuthMiddleware(apiKey: apiKey, sessionToken: nil)]
    )
  }

  private func rebuildClient() {
    self.underlyingClient = Client(
      serverURL: baseURL,
      transport: URLSessionTransport(),
      middlewares: [AuthMiddleware(apiKey: apiKey, sessionToken: sessionToken)]
    )
  }

  // MARK: - Authentication

  /// Authenticate a user and store the session token.
  @discardableResult
  public func authenticate(
    externalUserId: String,
    displayName: String,
    avatarUrl: URL? = nil
  ) async throws -> User {
    let response = try await underlyingClient.createUser(
      .init(body: .json(.init(
        externalUserId: externalUserId,
        displayName: displayName,
        avatarUrl: avatarUrl?.absoluteString
      )))
    )

    switch response {
    case .ok(let ok):
      let data = try ok.body.json
      self.sessionToken = data.sessionToken
      rebuildClient()
      return User(
        userId: data.id,
        sessionToken: data.sessionToken,
        externalUserId: data.externalUserId,
        displayName: data.displayName,
        avatarUrl: data.avatarUrl
      )
    case .badRequest(let err):
      throw try mapError(err.body.json)
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, _):
      throw DifferentRequestsError.serverError(statusCode: statusCode, message: "Unexpected response")
    }
  }

  // MARK: - Requests

  /// List feature requests with sorting, filtering, and pagination.
  public func listRequests(
    sort: SortOrder = .recent,
    status: RequestStatus? = nil,
    limit: Int = 20,
    cursor: String? = nil
  ) async throws -> PaginatedRequests {
    let response = try await underlyingClient.listRequests(
      .init(query: .init(
        sort: .init(rawValue: sort.rawValue),
        status: status.map { .init(rawValue: $0.rawValue) } ?? nil,
        limit: limit,
        cursor: cursor
      ))
    )

    switch response {
    case .ok(let ok):
      let data = try ok.body.json
      return PaginatedRequests(
        requests: data.data.map { mapRequest($0) },
        cursor: data.cursor,
        hasMore: data.hasMore
      )
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, _):
      throw DifferentRequestsError.serverError(statusCode: statusCode, message: "Unexpected response")
    }
  }

  /// Get a single feature request by ID.
  public func getRequest(id: String) async throws -> Request {
    let response = try await underlyingClient.getRequest(
      .init(path: .init(requestId: id))
    )

    switch response {
    case .ok(let ok):
      return mapRequest(try ok.body.json)
    case .movedPermanently(let moved):
      let data = try moved.body.json
      throw DifferentRequestsError.merged(targetId: data.mergedIntoId)
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, _):
      throw DifferentRequestsError.serverError(statusCode: statusCode, message: "Unexpected response")
    }
  }

  /// Submit a new feature request. Requires authentication.
  public func submitRequest(title: String, body: String) async throws -> Request {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.submitRequest(
      .init(body: .json(.init(title: title, body: body)))
    )

    switch response {
    case .created(let created):
      return mapRequest(try created.body.json)
    case .badRequest(let err):
      throw try mapError(err.body.json)
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, _):
      throw DifferentRequestsError.serverError(statusCode: statusCode, message: "Unexpected response")
    }
  }

  /// Search requests by title.
  public func searchRequests(query: String, limit: Int = 10) async throws -> [Request] {
    let response = try await underlyingClient.searchRequests(
      .init(query: .init(q: query, limit: limit))
    )

    switch response {
    case .ok(let ok):
      return try ok.body.json.map { mapRequest($0) }
    case .badRequest(let err):
      throw try mapError(err.body.json)
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, _):
      throw DifferentRequestsError.serverError(statusCode: statusCode, message: "Unexpected response")
    }
  }

  // MARK: - Voting

  /// Vote on a feature request. Requires authentication.
  public func vote(requestId: String, value: VoteValue) async throws -> Vote {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.vote(
      .init(
        path: .init(requestId: requestId),
        body: .json(.init(value: votePayload(value)))
      )
    )

    switch response {
    case .ok(let ok):
      let data = try ok.body.json
      return Vote(
        id: data.id,
        requestId: data.requestId,
        userId: data.userId,
        value: data.value,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt
      )
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .tooManyRequests(let err):
      let retryAfter = err.headers.Retry_hyphen_After ?? 60
      throw DifferentRequestsError.rateLimited(retryAfter: retryAfter)
    case .undocumented(let statusCode, _):
      throw DifferentRequestsError.serverError(statusCode: statusCode, message: "Unexpected response")
    }
  }

  // MARK: - Decline Reasons

  /// List decline reasons configured for this app.
  public func listDeclineReasons() async throws -> [DeclineReason] {
    let response = try await underlyingClient.listDeclineReasons(.init())

    switch response {
    case .ok(let ok):
      return try ok.body.json.map { reason in
        DeclineReason(
          id: reason.id,
          appId: reason.appId,
          label: reason.label,
          isDefault: reason.isDefault
        )
      }
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, _):
      throw DifferentRequestsError.serverError(statusCode: statusCode, message: "Unexpected response")
    }
  }

  // MARK: - Private Helpers

  private func mapRequest(_ r: Components.Schemas.Request) -> Request {
    Request(
      id: r.id,
      appId: r.appId,
      authorId: r.authorId,
      title: r.title,
      body: r.body,
      status: RequestStatus(rawValue: r.status.rawValue) ?? .open,
      source: RequestSource(rawValue: r.source.rawValue) ?? .sdk,
      score: r.score,
      mergedIntoId: r.mergedIntoId,
      declineReason: r.declineReason,
      declineReasonId: r.declineReasonId,
      declineReasonLabel: r.declineReasonLabel,
      authorDisplayName: r.authorDisplayName,
      authorExternalUserId: r.authorExternalUserId,
      authorAvatarUrl: r.authorAvatarUrl,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt
    )
  }

  private func votePayload(
    _ value: VoteValue
  ) -> Operations.vote.Input.Body.jsonPayload.valuePayload {
    switch value {
    case .upvote: return ._1
    case .downvote: return ._n1
    case .remove: return ._0
    }
  }

  private func mapError(_ err: Components.Schemas.ApiError) -> DifferentRequestsError {
    switch err.statusCode {
    case 404:
      return .notFound(message: err.message)
    case 400:
      return .validationError(message: err.message)
    case 401:
      return .notAuthenticated
    default:
      return .serverError(statusCode: err.statusCode, message: err.message)
    }
  }

}

// MARK: - Auth Middleware

package struct AuthMiddleware: ClientMiddleware, Sendable {
  let apiKey: String
  let sessionToken: String?

  package func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var request = request
    guard let appKeyName = HTTPField.Name("X-App-Key") else {
      throw AuthMiddlewareError.invalidHeaderName
    }
    request.headerFields[appKeyName] = apiKey
    if let token = sessionToken {
      request.headerFields[.authorization] = "Bearer \(token)"
    }
    return try await next(request, body, baseURL)
  }
}
