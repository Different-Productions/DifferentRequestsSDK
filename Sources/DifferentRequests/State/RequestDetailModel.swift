import Foundation

/// Observable state for the request detail view.
///
/// Manages loading a single request and voting on it.
/// All async work lives here — views only read state and call methods.
@Observable
@MainActor
public final class RequestDetailModel {

  // MARK: - Public State

  /// The loaded request, or `nil` if not yet loaded.
  public private(set) var request: Request?

  /// Whether the request is currently loading.
  public private(set) var isLoading = false

  /// Error from loading the request.
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
      self.error = .serverError(statusCode: 0, message: String(describing: error))
    }

    isLoading = false
  }

  // MARK: - Voting

  /// Vote on the current request. Returns the updated score.
  public func vote(value: VoteValue) async -> Int? {
    guard let id = requestId else { return nil }

    do {
      let result = try await client.vote(requestId: id, value: value)
      return result.newScore
    } catch {
      // Vote errors don't replace the loaded request — just return nil
      return nil
    }
  }
}
