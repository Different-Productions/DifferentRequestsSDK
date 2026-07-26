import DifferentRequestsProtos
import Foundation
import SwiftProtobuf

/// A client for the DifferentRequests API.
///
/// Every method is one rpc from the contract, taking and returning the contract's own types. There is
/// no translation layer and no parallel set of models: what
/// ``requests(statuses:sort:query:cursor:)`` hands back is the `DRListRequestsResponse` the server
/// sent.
///
/// Nothing here writes a URL. Paths come from the generated endpoint table, query keys from the
/// generated field names, and query values from the spellings the schema declares — so a call this
/// makes is addressed exactly as the server registered it.
///
/// Calls that act for a person need a session first; see
/// ``createSession(externalID:email:displayName:traits:)``. Which calls those are is not a rule to
/// remember: each rpc carries its audience, and one that needs a session is refused here before it
/// reaches the network.
public actor DifferentRequestsClient {

  /// Both directions carry protobuf. The same content type BacklogServer and the CMS speak.
  private static let protobufContentType = "application/x-protobuf"

  private let appKey: String
  private let baseURL: URL
  private let session: URLSession

  private var sessionToken: String?

  /// The signed-in person, once a session has been created.
  public private(set) var currentUser: DREndUser?

  // MARK: - Creation

  /// Assigns what it is given and nothing more. Use ``make(appKey:)`` for the ordinary case.
  public init(appKey: String, baseURL: URL, session: URLSession) {
    self.appKey = appKey
    self.baseURL = baseURL
    self.session = session
    self.sessionToken = nil
    self.currentUser = nil
  }

  /// A client pointed at production.
  ///
  /// - Parameter appKey: Your app key, from the DifferentRequests console.
  public static func make(appKey: String) -> DifferentRequestsClient {
    make(appKey: appKey, baseURL: productionBaseURL)
  }

  /// A client pointed at `baseURL`, for a staging endpoint.
  ///
  /// Owns its own `URLSession` so it does not entangle with a host app's, with timeouts short enough
  /// that a board tab does not hang on a stalled connection.
  public static func make(appKey: String, baseURL: URL) -> DifferentRequestsClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 20
    return DifferentRequestsClient(
      appKey: appKey,
      baseURL: baseURL,
      session: URLSession(configuration: configuration)
    )
  }

  /// Baked into every app built against this SDK version, so it cannot change without a coordinated
  /// release.
  public static let productionBaseURL: URL = {
    guard let url = URL(string: "https://api.differentrequests.com") else {
      preconditionFailure("DifferentRequests: the built-in base URL is not a URL — SDK bug.")
    }
    return url
  }()

  // MARK: - Configuration and identity

  /// What this app offers and how it presents itself.
  ///
  /// Fetch once per launch: which surfaces exist is a property of the tenant's plan, not something a
  /// client should assume.
  public func config() async throws -> DRGetConfigResponse {
    try await get(.getConfig, query: [])
  }

  /// Exchange your own identifier for this person for a session.
  ///
  /// Upsert: the same `externalID` returns the same person with the other fields refreshed, which is
  /// what lets someone reinstall and keep their votes.
  public func createSession(
    externalID: String,
    email: String?,
    displayName: String?,
    traits: [String: String]?
  ) async throws -> DRCreateSessionResponse {
    var body = DRCreateSessionRequest()
    body.externalID = externalID
    if let email {
      body.email = email
    }
    if let displayName {
      body.displayName = displayName
    }
    if let traits {
      body.traits = traits
    }

    let response: DRCreateSessionResponse = try await send(.createSession, body: body)
    sessionToken = response.sessionToken
    currentUser = response.user
    return response
  }

  // MARK: - The board

  /// A page of the board.
  ///
  /// - Parameters:
  ///   - statuses: Empty for everything still on the board.
  ///   - query: Free text over title and body. Also the search-before-submit path — the same ranking
  ///     and the same page shape, so duplicates are caught while writing rather than in triage.
  ///   - cursor: What the previous page handed back. Nil for the first page.
  public func requests(
    statuses: [DRRequestStatus],
    sort: DRRequestSort,
    query: String?,
    cursor: String?
  ) async throws -> DRListRequestsResponse {
    var items: [URLQueryItem] = []

    if let sortToken = sort.urlToken {
      items.append(URLQueryItem(name: DRListRequestsRequest.Field.sort, value: sortToken))
    }

    // Comma-separated, matching what the server reads: a repeated query parameter is spelled three
    // different ways by three different clients and one of them is always wrong.
    let statusTokens = statuses.compactMap(\.urlToken)
    if statusTokens.isEmpty == false {
      items.append(
        URLQueryItem(
          name: DRListRequestsRequest.Field.statuses,
          value: statusTokens.joined(separator: ",")
        )
      )
    }

    if let query, query.isEmpty == false {
      items.append(URLQueryItem(name: DRListRequestsRequest.Field.query, value: query))
    }
    if let cursor, cursor.isEmpty == false {
      items.append(URLQueryItem(name: DRListRequestsRequest.Field.cursor, value: cursor))
    }

    return try await get(.listRequests, query: items)
  }

  public func request(id: String) async throws -> DRGetRequestResponse {
    try await get(.getRequest(requestId: id), query: [])
  }

  /// Submit a request. It comes back with the author's own vote already counted.
  public func submit(title: String, body: String) async throws -> DRCreateRequestResponse {
    var payload = DRCreateRequestRequest()
    payload.title = title
    payload.body = body
    return try await send(.createRequest, body: payload)
  }

  // MARK: - Votes and follows

  /// Idempotent: voting twice is one vote.
  public func vote(requestID: String) async throws -> DRVoteResponse {
    try await send(.vote(requestId: requestID), body: DRVoteRequest())
  }

  /// Idempotent: clearing a vote nobody cast succeeds.
  public func clearVote(requestID: String) async throws -> DRClearVoteResponse {
    try await send(.clearVote(requestId: requestID), body: DRClearVoteRequest())
  }

  /// Follow for updates without adding demand. Voting already follows implicitly.
  public func follow(requestID: String) async throws -> DRFollowResponse {
    try await send(.follow(requestId: requestID), body: DRFollowRequest())
  }

  public func unfollow(requestID: String) async throws -> DRUnfollowResponse {
    try await send(.unfollow(requestId: requestID), body: DRUnfollowRequest())
  }

  // MARK: - Comments

  /// A page of a thread, oldest first.
  public func comments(requestID: String, cursor: String?) async throws -> DRListCommentsResponse {
    try await get(
      .listComments(requestId: requestID),
      query: Self.cursorQuery(cursor, named: DRListCommentsRequest.Field.cursor)
    )
  }

  public func comment(requestID: String, body: String) async throws -> DRCreateCommentResponse {
    var payload = DRCreateCommentRequest()
    payload.body = body
    return try await send(.createComment(requestId: requestID), body: payload)
  }

  // MARK: - Notifications

  public func notifications(cursor: String?) async throws -> DRListNotificationsResponse {
    try await get(
      .listNotifications,
      query: Self.cursorQuery(cursor, named: DRListNotificationsRequest.Field.cursor)
    )
  }

  /// The badge count. Prefer this over paging the inbox to count unread rows.
  public func unreadCount() async throws -> DRGetUnreadCountResponse {
    try await get(.getUnreadCount, query: [])
  }

  public func markRead(notificationID: String) async throws -> DRMarkNotificationReadResponse {
    try await send(
      .markNotificationRead(notificationId: notificationID),
      body: DRMarkNotificationReadRequest()
    )
  }

  public func markAllRead() async throws -> DRMarkAllNotificationsReadResponse {
    try await send(.markAllNotificationsRead, body: DRMarkAllNotificationsReadRequest())
  }

  // MARK: - Devices

  /// Register this device for push. Call on every launch: a token rotates on reinstall and Apple can
  /// invalidate one silently, so this is an upsert rather than a one-time write.
  ///
  /// - Parameters:
  ///   - tokenData: The `Data` handed to
  ///     `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
  ///   - environment: Which APNs environment minted the token. A sandbox token pushed to production
  ///     fails per-token with no useful error, so the caller states it.
  public func registerDevice(
    tokenData: Data,
    environment: DRPushEnvironment
  ) async throws -> DRRegisterDeviceResponse {
    var payload = DRRegisterDeviceRequest()
    payload.token = Self.hexString(from: tokenData)
    payload.environment = environment
    return try await send(.registerDevice, body: payload)
  }

  /// Drop a device, by the id registration handed back.
  public func unregisterDevice(deviceID: String) async throws -> DRUnregisterDeviceResponse {
    try await send(.unregisterDevice(deviceId: deviceID), body: DRUnregisterDeviceRequest())
  }

  // MARK: - Public surfaces

  /// The roadmap, as columns in display order. `DRAppConfig.roadmapEnabled` says whether to offer it.
  public func roadmap() async throws -> DRGetRoadmapResponse {
    try await get(.getRoadmap, query: [])
  }

  /// Published changelog entries, newest first. See `DRAppConfig.changelogEnabled`.
  public func changelog(cursor: String?) async throws -> DRListChangelogResponse {
    try await get(
      .listChangelog,
      query: Self.cursorQuery(cursor, named: DRListChangelogRequest.Field.cursor)
    )
  }

  // MARK: - Calling

  /// A read: no body, query parameters if there are any.
  private func get<Answer: Message>(
    _ endpoint: DRRequestsServiceEndpoint,
    query: [URLQueryItem]
  ) async throws -> Answer {
    try await perform(endpoint, query: query, body: nil)
  }

  /// A write: the request message as the body.
  private func send<Answer: Message>(
    _ endpoint: DRRequestsServiceEndpoint,
    body: some Message
  ) async throws -> Answer {
    try await perform(endpoint, query: [], body: try body.serializedData())
  }

  /// Builds the request, sends it, and decodes what came back.
  ///
  /// The audience check happens before anything is sent, so an unauthenticated call costs no round
  /// trip and reports the rpc that needed a session rather than a bare 401.
  private func perform<Answer: Message>(
    _ endpoint: DRRequestsServiceEndpoint,
    query: [URLQueryItem],
    body: Data?
  ) async throws -> Answer {
    let rpc = endpoint.rpc
    if rpc.audience == .endUser, sessionToken == nil {
      throw DifferentRequestsError.notAuthenticated(rpc)
    }

    guard var components = URLComponents(
      url: baseURL.appendingPathComponent(endpoint.path),
      resolvingAgainstBaseURL: false
    ) else {
      throw DifferentRequestsError.invalidBaseURL(baseURL)
    }
    if query.isEmpty == false {
      components.queryItems = query
    }
    guard let url = components.url else {
      throw DifferentRequestsError.invalidBaseURL(baseURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = Self.httpMethod(for: rpc)
    request.setValue(Self.protobufContentType, forHTTPHeaderField: "Accept")
    request.setValue(appKey, forHTTPHeaderField: "X-App-Key")
    if let sessionToken {
      request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
    }
    if let body {
      request.httpBody = body
      request.setValue(Self.protobufContentType, forHTTPHeaderField: "Content-Type")
    }

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: request)
    } catch {
      throw DifferentRequestsError.networkError(underlying: error)
    }

    guard let http = response as? HTTPURLResponse else {
      throw DifferentRequestsError.notAnHTTPResponse
    }

    // The status says only whether the body is the answer or a failure. Which failure is in the
    // body, because a status code cannot distinguish "upgrade to Pro" from "not your request".
    guard (200..<300).contains(http.statusCode) else {
      guard let apiError = try? DRApiError(serializedBytes: [UInt8](data)) else {
        throw DifferentRequestsError.unreadableError(byteCount: data.count)
      }
      throw DifferentRequestsError.api(apiError)
    }

    do {
      return try Answer(serializedBytes: [UInt8](data))
    } catch {
      throw DifferentRequestsError.decodingFailed(rpc, underlying: error)
    }
  }

  private static func httpMethod(for rpc: DRRequestsServiceRPC) -> String {
    switch rpc.method {
    case .get: return "GET"
    case .post: return "POST"
    case .put: return "PUT"
    case .delete: return "DELETE"
    case .unspecified, .UNRECOGNIZED:
      // Unreachable: endpoint-gen refuses to emit an rpc whose route is incomplete.
      return "GET"
    }
  }

  private static func cursorQuery(_ cursor: String?, named name: String) -> [URLQueryItem] {
    guard let cursor, cursor.isEmpty == false else {
      return []
    }
    return [URLQueryItem(name: name, value: cursor)]
  }

  /// APNs tokens are conventionally written as lowercase hex, so callers hand over the raw `Data` and
  /// never do this themselves.
  private static func hexString(from data: Data) -> String {
    data.map { byte in String(format: "%02x", byte) }.joined()
  }
}
