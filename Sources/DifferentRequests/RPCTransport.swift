import DifferentRequestsProtos
import Foundation

/// One call to the API: an rpc, its serialized request, and the credentials to present.
public struct RPCCall: Sendable {
  public let method: RequestsServiceMethod

  /// The request message, already serialized to protobuf binary.
  public let body: Data

  public let appKey: String

  /// Absent until ``DifferentRequestsClient/createSession(externalID:email:displayName:traits:)``
  /// has run. An rpc whose audience is `.endUser` is refused before it is sent when this
  /// is absent, so an unauthenticated call never reaches the network.
  public let sessionToken: String?

  public init(method: RequestsServiceMethod, body: Data, appKey: String, sessionToken: String?) {
    self.method = method
    self.body = body
    self.appKey = appKey
    self.sessionToken = sessionToken
  }
}

/// What came back.
public struct RPCResult: Sendable {
  /// Whether `body` holds the rpc's response message rather than an `ApiError`.
  ///
  /// This is the only thing read off the HTTP status, and reading it is not the same as
  /// interpreting it: *which* failure occurred is carried by `ApiError.code` in the body,
  /// because a status code cannot distinguish "upgrade to Pro" from "not your request".
  public let isSuccess: Bool

  /// Protobuf binary, either way.
  public let body: Data

  public init(isSuccess: Bool, body: Data) {
    self.isSuccess = isSuccess
    self.body = body
  }
}

/// How a call reaches the API.
///
/// A seam, so tests drive the client without a network and a host app can route calls
/// through its own stack. The client owns serialization and error mapping; a transport
/// only moves bytes.
public protocol RPCTransport: Sendable {
  func send(_ call: RPCCall, baseURL: URL) async throws -> RPCResult
}

/// The default transport: one POST per call, protobuf binary in and out.
public struct URLSessionRPCTransport: RPCTransport {
  private let session: URLSession

  /// - Parameter session: Injected rather than reached for, so a caller can supply one
  ///   with its own configuration, and tests can supply one that never leaves the process.
  public init(session: URLSession) {
    self.session = session
  }

  public func send(_ call: RPCCall, baseURL: URL) async throws -> RPCResult {
    guard let url = URL(string: call.method.path, relativeTo: baseURL) else {
      throw DifferentRequestsError.invalidBaseURL(baseURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = call.body
    request.setValue(Self.contentType, forHTTPHeaderField: "Content-Type")
    request.setValue(Self.contentType, forHTTPHeaderField: "Accept")
    request.setValue(call.appKey, forHTTPHeaderField: "X-App-Key")
    if let token = call.sessionToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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

    return RPCResult(isSuccess: (200...299).contains(http.statusCode), body: data)
  }

  /// There is no JSON alternative to negotiate, so this is stated rather than configured.
  private static let contentType = "application/proto"
}
