import Foundation
import SwiftUI

/// Observable state for the request detail view.
///
/// Manages loading a single request and voting on it.
/// Drives ``RequestDetailView`` reactively via `@Observable`.
///
/// ```swift
/// let model = RequestDetailModel(client: client)
/// await model.load(id: "request-123")
/// ```
@Observable
@MainActor
public final class RequestDetailModel {

  // MARK: - Public State

  /// The loaded request, or `nil` if not yet loaded.
  public private(set) var request: Request?

  /// Whether the request is currently loading.
  public private(set) var isLoading = false

  /// The most recent error, if any.
  public private(set) var error: DifferentRequestsError?

  // MARK: - Private State

  private let client: DifferentRequestsClient
  private var requestId: String?

  // MARK: - Initialization

  /// Creates a request detail model.
  /// - Parameter client: The DifferentRequests client to use for API calls.
  public init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Load a request by ID.
  /// - Parameter id: The request ID to load.
  public func load(id: String) async {
    requestId = id
    isLoading = true
    error = nil

    do {
      request = try await client.getRequest(id: id)
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }

    isLoading = false
  }

  // MARK: - Voting

  /// Vote on the current request, then reload to reflect the updated score.
  /// - Parameter value: The vote direction.
  public func vote(value: VoteValue) async {
    guard let id = requestId else { return }

    do {
      try await client.vote(requestId: id, value: value)
      await load(id: id)
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }
  }
}
