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

  /// The authenticated user's ID, set by ``authenticate(externalUserId:displayName:avatarUrl:email:traits:)``.
  ///
  /// Comments don't carry a per-item "is mine" flag the way votes carry
  /// `myVote`, so SDK views compare a comment's `authorId` against this to
  /// decide whether to show a delete affordance.
  public private(set) var currentUserId: String?

  /// The authenticated user's display name, set alongside ``currentUserId``.
  ///
  /// Used to render an optimistically-inserted comment before the server
  /// response (which carries the authoritative `authorDisplayName`) comes back.
  public private(set) var currentUserDisplayName: String?

  /// The default production API base URL.
  ///
  /// This host is baked into every app that uses `init(apiKey:)`, so it cannot
  /// change without a coordinated SDK release. Both `api.different.productions`
  /// (the previous default) and the raw API Gateway endpoint it replaced
  /// (`kstb23efj8.execute-api.us-east-1.amazonaws.com`) stay served by the API
  /// indefinitely, so apps built against older SDK versions keep working.
  private static let defaultBaseURL: URL = {
    guard let url = URL(string: "https://api.differentrequests.com") else {
      preconditionFailure("DifferentRequests: built-in default base URL is invalid — SDK bug.")
    }
    return url
  }()

  // MARK: - Initialization

  /// Create a client with your API key, pointed at the production API.
  ///
  /// Get your API key from the DifferentRequests console.
  /// - Parameter apiKey: Your app's API key.
  public init(apiKey: String) {
    self.init(apiKey: apiKey, baseURL: DifferentRequestsClient.defaultBaseURL)
  }

  /// Create a client with your API key and a custom base URL.
  ///
  /// Use this to point at a staging or self-hosted DifferentRequests backend.
  /// - Parameters:
  ///   - apiKey: Your app's API key.
  ///   - baseURL: The API base URL to use instead of production.
  public init(apiKey: String, baseURL: URL) {
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
  ///
  /// - Parameters:
  ///   - externalUserId: Your app's stable identifier for this user.
  ///   - displayName: The user's display name.
  ///   - avatarUrl: Optional avatar URL.
  ///   - email: Optional contact email.
  ///   - traits: Optional key/value attributes (plan tier, MRR, cohort, …) used
  ///     for segmentation. Passing this replaces the user's stored traits.
  public func authenticate(
    externalUserId: String,
    displayName: String,
    avatarUrl: URL?,
    email: String?,
    traits: [String: String]?
  ) async throws -> User {
    let traitsPayload: Operations.createUser.Input.Body.jsonPayload.traitsPayload?
    if let traits {
      traitsPayload = .init(additionalProperties: traits)
    } else {
      traitsPayload = nil
    }

    let response = try await underlyingClient.createUser(
      .init(body: .json(.init(
        externalUserId: externalUserId,
        displayName: displayName,
        avatarUrl: avatarUrl?.absoluteString,
        email: email,
        traits: traitsPayload
      )))
    )

    switch response {
    case .ok(let ok):
      let data = try ok.body.json
      self.sessionToken = data.sessionToken
      self.currentUserId = data.id
      self.currentUserDisplayName = data.displayName
      rebuildClient()
      let traitsDict: [String: String]
      if let additional = data.traits?.additionalProperties {
        traitsDict = additional
      } else {
        traitsDict = [:]
      }
      return User(
        userId: data.id,
        sessionToken: data.sessionToken,
        externalUserId: data.externalUserId,
        displayName: data.displayName,
        avatarUrl: data.avatarUrl,
        email: data.email,
        traits: traitsDict
      )
    case .badRequest(let err):
      throw try mapError(err.body.json)
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
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
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
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
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
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
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
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
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  // MARK: - Voting

  /// Vote on a feature request. Requires authentication.
  public func vote(requestId: String, value: VoteValue) async throws -> VoteResult {
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
      let vote: Vote?
      if let v = data.vote {
        vote = Vote(
          id: v.id,
          requestId: v.requestId,
          userId: v.userId,
          value: v.value,
          createdAt: parseDate(v.createdAt)
        )
      } else {
        vote = nil
      }
      return VoteResult(vote: vote, newScore: data.newScore)
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  // MARK: - Comments

  /// List comments on a feature request, oldest first.
  public func listComments(
    requestId: String,
    limit: Int = 20,
    cursor: String? = nil
  ) async throws -> PaginatedComments {
    let response = try await underlyingClient.listComments(
      .init(
        path: .init(requestId: requestId),
        query: .init(limit: limit, cursor: cursor)
      )
    )

    switch response {
    case .ok(let ok):
      let data = try ok.body.json
      return PaginatedComments(
        comments: data.data.map { mapComment($0) },
        cursor: data.cursor,
        hasMore: data.hasMore
      )
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  /// Post a comment on a feature request. Requires authentication.
  public func postComment(requestId: String, body: String) async throws -> Comment {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.postComment(
      .init(
        path: .init(requestId: requestId),
        body: .json(.init(body: body))
      )
    )

    switch response {
    case .created(let created):
      return mapComment(try created.body.json)
    case .badRequest(let err):
      throw try mapError(err.body.json)
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  /// Delete a comment you authored. Requires authentication.
  ///
  /// There is no admin delete from the SDK — deleting another user's
  /// comment throws ``DifferentRequestsError/forbidden(message:)``.
  public func deleteComment(requestId: String, commentId: String) async throws {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.deleteComment(
      .init(path: .init(requestId: requestId, commentId: commentId))
    )

    switch response {
    case .noContent:
      return
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .forbidden(let err):
      throw try mapError(err.body.json)
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  // MARK: - Devices

  /// Register (or refresh) an APNs device token for the authenticated user. Requires authentication.
  ///
  /// Idempotent — calling this again with the same token is safe and will
  /// not create a duplicate registration; a stale token is simply overwritten
  /// on the next call with the current one.
  ///
  /// This method only submits the token to the DifferentRequests backend. It
  /// does not request notification permission or trigger APNs registration —
  /// call ``PushNotifications/requestPushAuthorization()`` first, then pass
  /// this method the `Data` your app receives in its own
  /// `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
  /// delegate callback. The raw `Data` is converted to the lowercase-hex
  /// string form APNs tokens are conventionally represented as before being
  /// sent — callers do not need to do this conversion themselves.
  ///
  /// - Parameter tokenData: The raw device token `Data` handed to
  ///   `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
  /// - Returns: The stored registration record (token hash, not the raw token).
  public func registerDevice(tokenData: Data) async throws -> Device {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.registerDevice(
      .init(body: .json(.init(token: hexString(from: tokenData))))
    )

    switch response {
    case .created(let created):
      let data = try created.body.json
      return Device(
        tokenHash: data.tokenHash,
        createdAt: parseDate(data.createdAt),
        updatedAt: parseDate(data.updatedAt)
      )
    case .badRequest(let err):
      throw try mapError(err.body.json)
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  /// Unregister a device token for the authenticated user (e.g. on sign-out). Requires authentication.
  ///
  /// A no-op if the token was never registered or was already unregistered —
  /// this never throws `.notFound`.
  ///
  /// - Parameter tokenData: The same raw device token `Data` previously
  ///   passed to ``registerDevice(tokenData:)``.
  public func unregisterDevice(tokenData: Data) async throws {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.unregisterDevice(
      .init(path: .init(token: hexString(from: tokenData)))
    )

    switch response {
    case .noContent:
      return
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }


  // MARK: - Following

  /// Explicitly follow a feature request. Requires authentication.
  ///
  /// Following also happens automatically when you submit, vote (value != 0),
  /// or comment on a request — call this only for an explicit follow toggle
  /// the user requests independent of those actions.
  public func follow(requestId: String) async throws {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.followRequest(
      .init(path: .init(requestId: requestId))
    )

    switch response {
    case .noContent:
      return
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  /// Explicitly unfollow a feature request. Requires authentication.
  public func unfollow(requestId: String) async throws {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.unfollowRequest(
      .init(path: .init(requestId: requestId))
    )

    switch response {
    case .noContent:
      return
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  /// Get a feature request's follower count.
  ///
  /// Only the count is available — the SDK never exposes the raw list of
  /// who follows a request.
  public func followerCount(requestId: String) async throws -> Int {
    let response = try await underlyingClient.getFollowerCount(
      .init(path: .init(requestId: requestId))
    )

    switch response {
    case .ok(let ok):
      return try ok.body.json.count
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  /// List the current user's followed requests, most recently followed first. Requires authentication.
  public func listFollowedRequests(
    limit: Int = 20,
    cursor: String? = nil
  ) async throws -> PaginatedFollows {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.listMyFollows(
      .init(query: .init(limit: limit, cursor: cursor))
    )

    switch response {
    case .ok(let ok):
      let data = try ok.body.json
      return PaginatedFollows(
        follows: data.data.map { mapFollow($0) },
        cursor: data.cursor,
        hasMore: data.hasMore
      )
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }


  // MARK: - Notifications

  /// List the authenticated user's in-app inbox, most recent first. Requires authentication.
  ///
  /// Populated by an async fan-out worker off status changes and new
  /// comments on requests you follow — never written synchronously by
  /// whatever triggered it, so expect a short, unspecified delay.
  public func listNotifications(
    limit: Int = 20,
    cursor: String? = nil
  ) async throws -> PaginatedNotifications {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.listMyNotifications(
      .init(query: .init(limit: limit, cursor: cursor))
    )

    switch response {
    case .ok(let ok):
      let data = try ok.body.json
      return PaginatedNotifications(
        notifications: data.data.map { mapNotification($0) },
        cursor: data.cursor,
        hasMore: data.hasMore
      )
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  /// Get the authenticated user's unread notification count, for a badge. Requires authentication.
  ///
  /// Prefer this over paginating ``listNotifications(limit:cursor:)`` just to count unread rows.
  public func unreadNotificationCount() async throws -> Int {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.getUnreadNotificationCount(.init())

    switch response {
    case .ok(let ok):
      return try ok.body.json.count
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  /// Mark one notification read. Requires authentication.
  public func markNotificationRead(id: String) async throws -> AppNotification {
    guard sessionToken != nil else {
      throw DifferentRequestsError.notAuthenticated
    }

    let response = try await underlyingClient.markNotificationRead(
      .init(path: .init(notificationId: id))
    )

    switch response {
    case .ok(let ok):
      return mapNotification(try ok.body.json)
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .notFound(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
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
          isDefault: reason.isDefault,
          createdAt: parseDate(reason.createdAt)
        )
      }
    case .unauthorized(let err):
      throw try mapError(err.body.json)
    case .undocumented(let statusCode, let payload):
      throw mapUndocumented(statusCode: statusCode, payload)
    }
  }

  // MARK: - Private Helpers

  private func mapRequest(_ r: Components.Schemas.Request) -> Request {
    let status: RequestStatus
    if let parsed = RequestStatus(rawValue: r.status.rawValue) {
      status = parsed
    } else {
      status = .open
    }

    let source: RequestSource
    if let parsed = RequestSource(rawValue: r.source.rawValue) {
      source = parsed
    } else {
      source = .sdk
    }

    return Request(
      id: r.id,
      appId: r.appId,
      authorId: r.authorId,
      title: r.title,
      body: r.body,
      status: status,
      source: source,
      score: r.score,
      myVote: r.myVote,
      mergedIntoId: r.mergedIntoId,
      declineReason: r.declineReason,
      declineReasonId: r.declineReasonId,
      declineReasonLabel: r.declineReasonLabel,
      authorDisplayName: r.authorDisplayName,
      authorExternalUserId: r.authorExternalUserId,
      authorAvatarUrl: r.authorAvatarUrl,
      createdAt: parseDate(r.createdAt),
      updatedAt: parseDate(r.updatedAt)
    )
  }

  private func mapComment(_ c: Components.Schemas.Comment) -> Comment {
    Comment(
      id: c.id,
      requestId: c.requestId,
      appId: c.appId,
      authorId: c.authorId,
      authorDisplayName: c.authorDisplayName,
      isOfficial: c.isOfficial,
      body: c.body,
      hidden: c.hidden,
      createdAt: parseDate(c.createdAt)
    )
  }

  private func mapFollow(_ f: Components.Schemas.Follow) -> Follow {
    Follow(
      requestId: f.requestId,
      userId: f.userId,
      appId: f.appId,
      createdAt: parseDate(f.createdAt)
    )
  }

  private func mapNotification(_ n: Components.Schemas.Notification) -> AppNotification {
    let type: NotificationType
    switch n._type {
    case .status_change: type = .statusChange
    case .comment: type = .comment
    case .official_reply: type = .officialReply
    }

    return AppNotification(
      id: n.id,
      requestId: n.requestId,
      type: type,
      status: n.status,
      commentId: n.commentId,
      read: n.read,
      createdAt: n.createdAt
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

  /// Convert a raw APNs device token to its conventional lowercase-hex string representation.
  private func hexString(from data: Data) -> String {
    data.map { byte in String(format: "%02x", byte) }.joined()
  }

  private func parseDate(_ string: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: string) {
      return date
    }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: string) ?? Date.now
  }

  private func mapError(_ err: Components.Schemas.ApiError) -> DifferentRequestsError {
    switch err.statusCode {
    case 404:
      return .notFound(message: err.message)
    case 403:
      return .forbidden(message: err.message)
    case 400:
      return .validationError(message: err.message)
    case 401:
      return .notAuthenticated
    default:
      return .serverError(statusCode: err.statusCode, message: err.message)
    }
  }

  /// Map a response the API contract doesn't document to a typed error. A 429
  /// becomes `.rateLimited` (reading `Retry-After` when the server sends it) so
  /// callers can back off; anything else is a generic server error.
  private func mapUndocumented(
    statusCode: Int,
    _ payload: UndocumentedPayload
  ) -> DifferentRequestsError {
    if statusCode == 429 {
      return .rateLimited(retryAfter: retryAfterSeconds(payload))
    }
    return .serverError(statusCode: statusCode, message: "Unexpected response")
  }

  private func retryAfterSeconds(_ payload: UndocumentedPayload) -> Int {
    guard let name = HTTPField.Name("Retry-After"),
          let raw = payload.headerFields[name],
          let seconds = Int(raw) else {
      return 0
    }
    return seconds
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
