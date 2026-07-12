import Foundation
import SwiftUI

/// Observable state for a single request's follow toggle.
///
/// Unlike ``CommentsThreadModel``, this manages one boolean-ish piece of
/// state per request (am I following it, and how many followers does it
/// have) rather than a list. `toggle()` flips ``isFollowing`` immediately and
/// rolls back with ``error`` set if the server rejects the change — the same
/// optimistic-update-with-rollback shape as ``CommentsThreadModel/post()``
/// and ``CommentsThreadModel/delete(commentId:)``.
///
/// ```swift
/// let model = FollowModel(client: client, requestId: "request-123")
/// await model.load()
/// await model.toggle()
/// ```
@Observable
@MainActor
public final class FollowModel {

  // MARK: - Public State

  /// Whether the current user follows this request.
  public private(set) var isFollowing: Bool

  /// The request's total follower count, or `nil` until ``load()`` completes.
  public private(set) var followerCount: Int?

  /// Whether the initial load is in progress.
  public private(set) var isLoading = false

  /// Whether a follow/unfollow toggle is in progress.
  public private(set) var isToggling = false

  /// The most recent error, if any.
  public private(set) var error: DifferentRequestsError?

  // MARK: - Private State

  private let client: DifferentRequestsClient
  private let requestId: String

  // MARK: - Initialization

  /// Creates a follow model.
  /// - Parameters:
  ///   - client: The DifferentRequests client to use for API calls.
  ///   - requestId: The request whose follow state this model manages.
  ///   - isFollowing: The known initial follow state (e.g. from a request
  ///     list already carrying it), if any. Defaults to `false` until
  ///     ``load()`` is called.
  public init(client: DifferentRequestsClient, requestId: String, isFollowing: Bool = false) {
    self.client = client
    self.requestId = requestId
    self.isFollowing = isFollowing
  }

  // MARK: - Loading

  /// Load the request's follower count.
  ///
  /// The API only exposes a follower count, not the follower list, so this
  /// does not (and cannot) refresh ``isFollowing`` from the server — set that
  /// at init time or via ``toggle()``.
  public func load() async {
    isLoading = true
    error = nil

    do {
      followerCount = try await client.followerCount(requestId: requestId)
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }

    isLoading = false
  }

  // MARK: - Toggling

  /// Flip the follow state. Requires authentication.
  ///
  /// Updates ``isFollowing`` and ``followerCount`` immediately, then rolls
  /// both back and sets ``error`` if the server call fails.
  public func toggle() async {
    guard !isToggling else { return }

    let wasFollowing = isFollowing
    let previousCount = followerCount
    error = nil
    isToggling = true

    isFollowing = !wasFollowing
    if let previousCount {
      followerCount = wasFollowing ? max(0, previousCount - 1) : previousCount + 1
    }

    do {
      if wasFollowing {
        try await client.unfollow(requestId: requestId)
      } else {
        try await client.follow(requestId: requestId)
      }
    } catch let err as DifferentRequestsError {
      isFollowing = wasFollowing
      followerCount = previousCount
      error = err
    } catch {
      isFollowing = wasFollowing
      followerCount = previousCount
      self.error = .networkError(underlying: error)
    }

    isToggling = false
  }
}
