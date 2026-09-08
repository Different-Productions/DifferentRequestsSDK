import Foundation

/// A base URL this SDK is willing to dial.
///
/// Every call carries `X-App-Key`, and every call for a person carries their session token. Over
/// plain `http` both cross the wire in the clear, and nothing about the request looks wrong — it
/// works, which is the problem.
///
/// A type rather than a check inside the client's initializer, so **the refusal happens where the
/// URL is supplied** rather than on the first call. A developer who typos a staging address is told
/// which URL was refused, at the line that wrote it, instead of watching requests succeed.
public struct SecureBaseURL: Sendable, Equatable {
  public let url: URL

  /// Where a released SDK points unless a developer says otherwise. Known `https`, so it is built
  /// through the trusted path and cannot fail.
  public static let production = SecureBaseURL(trusted: DifferentRequestsClient.productionBaseURL)

  private init(trusted url: URL) {
    self.url = url
  }

  /// A staging or local address, refused unless it is `https`.
  ///
  /// - Throws: ``DifferentRequestsError/invalidBaseURL(_:)`` naming the URL that was refused.
  public init(_ url: URL) throws {
    guard url.scheme?.lowercased() == "https" else {
      throw DifferentRequestsError.invalidBaseURL(url)
    }
    self.url = url
  }
}
