import DifferentRequestsProtos
import Foundation
import SwiftProtobuf

/// A client for the DifferentRequests API.
///
/// Every method is one rpc from the contract, taking and returning the contract's own
/// types. There is no translation layer and no parallel set of models: what
/// ``listRequests(statuses:sort:query:cursor:)`` hands back is the
/// `ListRequestsResponse` the server sent.
///
/// Calls that act on behalf of a person need a session first — see
/// ``createSession(externalID:email:displayName:traits:)``. Which calls those are is not a
/// rule to remember: each rpc carries its audience, and one whose audience is `.endUser` is
/// refused locally before it is sent.
public actor DifferentRequestsClient {
  private let appKey: String
  private let baseURL: URL
  private let transport: any RPCTransport

  private var sessionToken: String?

  /// The signed-in user, once ``createSession(externalID:email:displayName:traits:)`` has
  /// run. Views compare a comment's author against this to decide what a person may act on.
  public private(set) var currentUser: EndUser?

  // MARK: - Creation

  /// Assigns what it is given and nothing more. Use ``make(appKey:)`` for the ordinary case.
  public init(appKey: String, baseURL: URL, transport: any RPCTransport) {
    self.appKey = appKey
    self.baseURL = baseURL
    self.transport = transport
    self.sessionToken = nil
    self.currentUser = nil
  }

  /// A client pointed at production over `URLSession`.
  ///
  /// - Parameter appKey: Your app key, from the DifferentRequests console.
  public static func make(appKey: String) -> DifferentRequestsClient {
    make(appKey: appKey, baseURL: productionBaseURL)
  }

  /// A client pointed at `baseURL` over `URLSession`. Use for a staging endpoint.
  public static func make(appKey: String, baseURL: URL) -> DifferentRequestsClient {
    DifferentRequestsClient(
      appKey: appKey,
      baseURL: baseURL,
      transport: URLSessionRPCTransport(session: URLSession(configuration: .default))
    )
  }

  /// Baked into every app built against this SDK version, so it cannot change without a
  /// coordinated release.
  public static let productionBaseURL: URL = {
    guard let url = URL(string: "https://api.differentrequests.com") else {
      preconditionFailure("DifferentRequests: the built-in base URL is not a URL — SDK bug.")
    }
    return url
  }()

  // MARK: - Configuration and identity

  /// What this app offers and how it presents itself. Fetch once per launch: which surfaces
  /// exist is a property of the tenant's plan, not something a client should assume.
  public func getConfig() async throws -> GetConfigResponse {
    try await call(.getConfig, GetConfigRequest())
  }

  /// Exchange your own identifier for this person for a session.
  ///
  /// Upsert: the same `externalID` returns the same user with the other fields refreshed,
  /// which is what lets someone reinstall and keep their votes.
  public func createSession(
    externalID: String,
    email: String?,
    displayName: String?,
    traits: [String: String]?
  ) async throws -> CreateSessionResponse {
    var request = CreateSessionRequest()
    request.externalID = externalID
    if let email {
      request.email = email
    }
    if let displayName {
      request.displayName = displayName
    }
    if let traits {
      request.traits = traits
    }

    let response: CreateSessionResponse = try await call(.createSession, request)
    sessionToken = response.sessionToken
    currentUser = response.user
    return response
  }

  // MARK: - The board

  /// A page of the board.
  ///
  /// - Parameters:
  ///   - statuses: Empty for everything still on the board.
  ///   - query: Free text over title and body. Also the search-before-submit path — the
  ///     same ranking and the same page shape, so duplicates are caught while writing
  ///     rather than in triage afterwards.
  public func listRequests(
    statuses: [RequestStatus],
    sort: RequestSort,
    query: String?,
    cursor: String?
  ) async throws -> ListRequestsResponse {
    var request = ListRequestsRequest()
    request.statuses = statuses
    request.sort = sort
    if let query {
      request.query = query
    }
    if let cursor {
      request.cursor = cursor
    }
    return try await call(.listRequests, request)
  }

  public func getRequest(id: String) async throws -> GetRequestResponse {
    var request = GetRequestRequest()
    request.requestID = id
    return try await call(.getRequest, request)
  }

  /// Submit a request. It comes back with the author's own vote already counted — asking
  /// for something and then having to vote for it reads as a bug.
  public func createRequest(title: String, body: String) async throws -> CreateRequestResponse {
    var request = CreateRequestRequest()
    request.title = title
    request.body = body
    return try await call(.createRequest, request)
  }

  // MARK: - Votes and follows

  /// Idempotent: voting twice is one vote. Returns the updated request so a list already on
  /// screen can be reconciled without refetching it.
  public func vote(requestID: String) async throws -> VoteResponse {
    var request = VoteRequest()
    request.requestID = requestID
    return try await call(.vote, request)
  }

  /// Idempotent: clearing a vote nobody cast succeeds.
  public func clearVote(requestID: String) async throws -> ClearVoteResponse {
    var request = ClearVoteRequest()
    request.requestID = requestID
    return try await call(.clearVote, request)
  }

  /// Follow for updates without adding demand. Voting already follows implicitly.
  public func follow(requestID: String) async throws -> FollowResponse {
    var request = FollowRequest()
    request.requestID = requestID
    return try await call(.follow, request)
  }

  public func unfollow(requestID: String) async throws -> UnfollowResponse {
    var request = UnfollowRequest()
    request.requestID = requestID
    return try await call(.unfollow, request)
  }

  // MARK: - Comments

  /// Oldest first, always — a discussion read newest-first is unreadable, so there is no
  /// sort to choose.
  public func listComments(
    requestID: String,
    cursor: String?
  ) async throws -> ListCommentsResponse {
    var request = ListCommentsRequest()
    request.requestID = requestID
    if let cursor {
      request.cursor = cursor
    }
    return try await call(.listComments, request)
  }

  public func createComment(requestID: String, body: String) async throws -> CreateCommentResponse {
    var request = CreateCommentRequest()
    request.requestID = requestID
    request.body = body
    return try await call(.createComment, request)
  }

  // MARK: - Notifications

  public func listNotifications(
    cursor: String?
  ) async throws -> ListNotificationsResponse {
    var request = ListNotificationsRequest()
    if let cursor {
      request.cursor = cursor
    }
    return try await call(.listNotifications, request)
  }

  /// The unread badge count. Prefer this over paging the inbox to count unread rows.
  public func getUnreadCount() async throws -> GetUnreadCountResponse {
    try await call(.getUnreadCount, GetUnreadCountRequest())
  }

  public func markNotificationRead(id: String) async throws -> MarkNotificationReadResponse {
    var request = MarkNotificationReadRequest()
    request.notificationID = id
    return try await call(.markNotificationRead, request)
  }

  public func markAllNotificationsRead() async throws -> MarkAllNotificationsReadResponse {
    try await call(.markAllNotificationsRead, MarkAllNotificationsReadRequest())
  }

  // MARK: - Devices

  /// Register this device for push. Call on every launch: a token rotates on reinstall and
  /// Apple can invalidate one silently, so this is an upsert rather than a one-time write.
  ///
  /// This only submits the token. Ask for notification permission first — see
  /// ``PushNotifications/requestPushAuthorization()`` — then pass the `Data` your app
  /// receives in `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
  ///
  /// - Parameter environment: Which APNs environment minted the token. A sandbox token
  ///   pushed to production fails per-token with no useful error, so the caller states it.
  public func registerDevice(
    tokenData: Data,
    environment: PushEnvironment
  ) async throws -> RegisterDeviceResponse {
    var request = RegisterDeviceRequest()
    request.token = Self.hexString(from: tokenData)
    request.environment = environment
    return try await call(.registerDevice, request)
  }

  /// Drop a device, e.g. on sign-out.
  public func unregisterDevice(deviceID: String) async throws -> UnregisterDeviceResponse {
    var request = UnregisterDeviceRequest()
    request.deviceID = deviceID
    return try await call(.unregisterDevice, request)
  }

  // MARK: - Public surfaces

  /// The roadmap, as columns in display order. Pro plan; `AppConfig.roadmapEnabled` says
  /// whether to offer it at all.
  public func getRoadmap() async throws -> GetRoadmapResponse {
    try await call(.getRoadmap, GetRoadmapRequest())
  }

  /// Published changelog entries, newest first. Pro plan; see `AppConfig.changelogEnabled`.
  public func listChangelog(cursor: String?) async throws -> ListChangelogResponse {
    var request = ListChangelogRequest()
    if let cursor {
      request.cursor = cursor
    }
    return try await call(.listChangelog, request)
  }

  // MARK: - Calling

  /// Serialize, send, decode. The one place any of those three happen.
  private func call<Response: Message>(
    _ method: RequestsServiceMethod,
    _ request: some Message
  ) async throws -> Response {
    if method.audience == .endUser, sessionToken == nil {
      throw DifferentRequestsError.notAuthenticated(method)
    }

    let result = try await transport.send(
      RPCCall(
        method: method,
        body: try request.serializedBytes(),
        appKey: appKey,
        sessionToken: sessionToken
      ),
      baseURL: baseURL
    )

    if result.isSuccess {
      do {
        return try Response(serializedBytes: result.body)
      } catch {
        throw DifferentRequestsError.decodingFailed(method, underlying: error)
      }
    }

    // A failure body is an ApiError encoded exactly like a response. When it will not
    // decode, there is nothing to branch on and saying so beats inventing a code.
    guard let apiError = try? ApiError(serializedBytes: result.body) else {
      throw DifferentRequestsError.unreadableError(byteCount: result.body.count)
    }
    throw DifferentRequestsError.api(apiError)
  }

  /// APNs tokens are conventionally written as lowercase hex, so callers hand over the raw
  /// `Data` and never do this themselves.
  private static func hexString(from data: Data) -> String {
    data.map { byte in String(format: "%02x", byte) }.joined()
  }
}
