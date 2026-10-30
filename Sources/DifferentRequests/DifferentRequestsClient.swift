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
/// ``createSession(externalID:email:displayName:proof:)``. Which calls those are is not a
/// rule to remember: each rpc carries its audience, and one that needs a session is refused here
/// before it reaches the network.
public actor DifferentRequestsClient {

  // Internal rather than private so `DifferentRequestsClient+Describe` can read them. Still not
  // public: `describeIntegration()` is the only way out, and it elides the key.
  let appKey: String
  let baseURL: SecureBaseURL

  /// This client's own session, apart from the host app's, with timeouts short enough that a board
  /// tab does not hang on a stalled connection.
  private let session: URLSession

  /// How long one request may wait between bytes.
  private static let requestTimeoutSeconds: TimeInterval = 15

  /// How long one request may take from start to finish.
  private static let resourceTimeoutSeconds: TimeInterval = 20

  private var sessionToken: String?

  /// The last answer to ``config()``, kept for the rest of this client's life.
  ///
  /// Only a successful read lands here. A read that threw leaves this nil so that whoever asks
  /// next reaches the server: a config read fails for the same reasons any read does, and a plan
  /// remembered as unreadable would keep every gated surface shut for the whole launch over one
  /// dropped connection.
  var configuration: DRGetConfigResponse?

  /// The signed-in person, once a session has been created.
  public private(set) var currentUser: DREndUser?

  /// What happened on the last call, so ``describeIntegration()`` can say whether anything has left
  /// the device at all.
  public private(set) var lastCall = LastCall()

  // MARK: - Creation

  /// A client for `appKey`, pointed at `baseURL`. Assigns what it is given and builds the one
  /// `URLSession` it owns.
  ///
  /// Takes a ``SecureBaseURL`` rather than a `URL`, so a plaintext address is refused where it is
  /// written rather than on the first call that carries a key over it.
  ///
  /// - Parameters:
  ///   - appKey: Your app key, from the DifferentRequests console.
  ///   - baseURL: Where the API is: `SecureBaseURL(service: .production)`, or a staging endpoint.
  public init(appKey: String, baseURL: SecureBaseURL) {
    self.appKey = appKey
    self.baseURL = baseURL
    let sessionConfiguration = URLSessionConfiguration.ephemeral
    sessionConfiguration.timeoutIntervalForRequest = Self.requestTimeoutSeconds
    sessionConfiguration.timeoutIntervalForResource = Self.resourceTimeoutSeconds
    self.session = URLSession(configuration: sessionConfiguration)
  }

  // MARK: - Configuration and identity

  /// What this app offers and how it presents itself.
  ///
  /// Read once and then remembered, so that asking is cheap enough to do from everywhere it
  /// matters. Which surfaces exist is a property of the tenant's plan rather than something a
  /// client may assume, and the screens that are gated on it ask for themselves — the roadmap,
  /// the changelog, and the composer under a request. Without the cache that is three round trips
  /// for one answer that cannot change between them, and the screens would go back to guessing to
  /// avoid paying it.
  ///
  /// The contract states this is fetched once per launch, so a tenant who upgrades mid-session is
  /// seen on the next one. That is the contract's decision, not an approximation of it.
  ///
  /// Two asks made before the first has answered both read. That costs one extra GET of a route
  /// with no side effects, which is a cheaper thing to be wrong about than a lock held across a
  /// network call.
  public func config() async throws -> DRGetConfigResponse {
    if let configuration {
      return configuration
    }
    let answer: DRGetConfigResponse = try await get(.getConfig, query: [])
    configuration = answer
    return answer
  }

  /// Exchange your own identifier for this person for a session.
  ///
  /// Upsert: the same `externalID` returns the same person with the other fields refreshed, which is
  /// what lets someone reinstall and keep their votes.
  ///
  /// - Parameter proof: Your backend vouching for this person, made with your app's signing secret
  ///   and built with ``DRIdentityProof/init(signature:expiresAt:)``. An app that has a signing
  ///   secret refuses every session without one, including for people it has seen before. `nil` for
  ///   an app that has none, which is every app until its developer asks for one.
  public func createSession(
    externalID: String,
    email: String?,
    displayName: String?,
    proof: DRIdentityProof?
  ) async throws -> DRCreateSessionResponse {
    var body = DRCreateSessionRequest()
    body.externalID = externalID
    if let email {
      body.email = email
    }
    if let displayName {
      body.displayName = displayName
    }
    if let proof {
      body.proof = proof
    }

    let response: DRCreateSessionResponse = try await send(.createSession, body: body)
    sessionToken = response.sessionToken
    currentUser = response.user
    return response
  }

  // MARK: - The board

  /// A page of the board, for the request the contract declares.
  ///
  /// Takes `DRListRequestsRequest` whole rather than its four fields: the message is what the
  /// server, the wire and this client have agreed on, and a caller that spells the fields out is a
  /// second place they can disagree. Empty is absent throughout, which is what proto3 means by an
  /// unset scalar — so an empty `query` or `cursor` simply does not become a query item.
  public func requests(_ asked: DRListRequestsRequest) async throws -> DRListRequestsResponse {
    var items: [URLQueryItem] = []

    if let sortToken = asked.sort.urlToken {
      items.append(URLQueryItem(name: DRListRequestsRequest.Field.sort, value: sortToken))
    }

    // Comma-separated, matching what the server reads: a repeated query parameter is spelled three
    // different ways by three different clients and one of them is always wrong.
    let statusTokens = asked.statuses.compactMap(\.urlToken)
    if statusTokens.isEmpty == false {
      items.append(
        URLQueryItem(
          name: DRListRequestsRequest.Field.statuses,
          value: statusTokens.joined(separator: ",")
        )
      )
    }

    if asked.query.isEmpty == false {
      items.append(URLQueryItem(name: DRListRequestsRequest.Field.query, value: asked.query))
    }
    if asked.cursor.isEmpty == false {
      items.append(URLQueryItem(name: DRListRequestsRequest.Field.cursor, value: asked.cursor))
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
      query: cursorQuery(cursor, named: DRListCommentsRequest.Field.cursor)
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
      query: cursorQuery(cursor, named: DRListNotificationsRequest.Field.cursor)
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
    try await send(.registerDevice, body: DRRegisterDeviceRequest(tokenData: tokenData, environment: environment))
  }

  /// Drop a device, by the id registration handed back. Returning without a throw means the server
  /// dropped it.
  public func unregisterDevice(deviceID: String) async throws {
    let endpoint = DRRequestsServiceEndpoint.unregisterDevice(deviceId: deviceID)
    var reply = Data()
    try await deliver(
      endpoint,
      request: try request(
        for: endpoint,
        at: try url(for: endpoint),
        carrying: try DRUnregisterDeviceRequest().serializedData()
      ),
      into: &reply
    )
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
      query: cursorQuery(cursor, named: DRListChangelogRequest.Field.cursor)
    )
  }

  // MARK: - Calling

  /// A read: no body, query parameters if there are any.
  private func get<Answer: Message>(
    _ endpoint: DRRequestsServiceEndpoint,
    query: [URLQueryItem]
  ) async throws -> Answer {
    try await perform(endpoint, request: try request(for: endpoint, at: try url(for: endpoint, query: query)))
  }

  /// A write: the request message as the body.
  private func send<Answer: Message>(
    _ endpoint: DRRequestsServiceEndpoint,
    body: some Message
  ) async throws -> Answer {
    try await perform(
      endpoint,
      request: try request(for: endpoint, at: try url(for: endpoint), carrying: try body.serializedData())
    )
  }

  /// The endpoint's address on the base URL.
  private func url(for endpoint: DRRequestsServiceEndpoint) throws -> URL {
    let base = try baseURL.dialable()
    return base.appendingPathComponent(endpoint.path)
  }

  /// The endpoint's address with `query` appended, or bare when `query` is empty.
  private func url(for endpoint: DRRequestsServiceEndpoint, query: [URLQueryItem]) throws -> URL {
    let address = try url(for: endpoint)
    guard query.isEmpty == false else {
      return address
    }
    guard var components = URLComponents(url: address, resolvingAgainstBaseURL: false) else {
      throw DifferentRequestsError(invalidBaseURL: baseURL.url)
    }
    components.queryItems = query
    guard let queried = components.url else {
      throw DifferentRequestsError(invalidBaseURL: baseURL.url)
    }
    return queried
  }

  /// A request for `endpoint` at `url`, with the rpc's method and every header but the body's.
  private func request(for endpoint: DRRequestsServiceEndpoint, at url: URL) throws -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = try endpoint.rpc.spelledMethod()
    request.setValue(DRMediaType.protobuf.rawValue, forHTTPHeaderField: DRHTTPHeaderName.accept.rawValue)
    request.setValue(appKey, forHTTPHeaderField: DRHTTPHeaderName.appKey.rawValue)
    request.setValue(
      SDKClient(process: .processInfo).header(),
      forHTTPHeaderField: DRHTTPHeaderName.client.rawValue
    )
    if let sessionToken {
      request.setValue(
        "\(DRAuthorizationScheme.bearer.rawValue) \(sessionToken)",
        forHTTPHeaderField: DRHTTPHeaderName.authorization.rawValue
      )
    }
    return request
  }

  /// A request for `endpoint` at `url` carrying `body`, a serialized request message.
  private func request(for endpoint: DRRequestsServiceEndpoint, at url: URL, carrying body: Data) throws -> URLRequest {
    var request = try request(for: endpoint, at: url)
    request.httpBody = body
    request.setValue(DRMediaType.protobuf.rawValue, forHTTPHeaderField: DRHTTPHeaderName.contentType.rawValue)
    return request
  }

  /// Sends the request and decodes what came back as the rpc's answer.
  private func perform<Answer: Message>(
    _ endpoint: DRRequestsServiceEndpoint,
    request: URLRequest
  ) async throws -> Answer {
    var reply = Data()
    try await deliver(endpoint, request: request, into: &reply)
    do {
      return try Answer(serializedBytes: [UInt8](reply))
    } catch {
      let failure = DifferentRequestsError(decodingFailed: endpoint.rpc, underlying: error)
      lastCall = LastCall(rpc: endpoint.rpc, status: lastCall.status, failure: failure)
      throw failure
    }
  }

  /// Sends `request` and writes a 2xx body into `reply`; any other answer throws.
  ///
  /// The audience check happens before anything is sent, so an unauthenticated call costs no round
  /// trip and reports the rpc that needed a session rather than a bare 401.
  private func deliver(
    _ endpoint: DRRequestsServiceEndpoint,
    request: URLRequest,
    into reply: inout Data
  ) async throws {
    let rpc = endpoint.rpc
    if rpc.audience.needsSession(), sessionToken == nil {
      throw DifferentRequestsError(notAuthenticated: rpc)
    }

    let answerBody: Data
    let response: URLResponse
    do {
      (answerBody, response) = try await session.data(for: request)
    } catch {
      let failure = DifferentRequestsError(networkFailure: error)
      lastCall = LastCall(rpc: rpc, status: 0, failure: failure)
      throw failure
    }

    guard let http = response as? HTTPURLResponse else {
      let failure = DifferentRequestsError(
        reason: .notAnHTTPResponse,
        message: "The transport returned a non-HTTP response."
      )
      lastCall = LastCall(rpc: rpc, status: 0, failure: failure)
      throw failure
    }
    let status = Int32(http.statusCode)

    // The status says only whether the body is the answer or a failure. Which failure is in the
    // body, because a status code cannot distinguish "upgrade to Pro" from "not your request".
    guard (200..<300).contains(http.statusCode) else {
      let refusal = DifferentRequestsError(failureBody: answerBody)
      lastCall = LastCall(rpc: rpc, status: status, failure: refusal)
      throw refusal
    }

    lastCall = LastCall(rpc: rpc, status: status)
    reply = answerBody
  }

  /// The query item carrying `cursor` under `name`, or none for the first page.
  private func cursorQuery(_ cursor: String?, named name: String) -> [URLQueryItem] {
    var items: [URLQueryItem] = []
    if let cursor, cursor.isEmpty == false {
      items.append(URLQueryItem(name: name, value: cursor))
    }
    return items
  }
}
