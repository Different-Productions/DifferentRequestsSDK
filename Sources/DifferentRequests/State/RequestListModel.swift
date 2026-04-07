import Foundation

/// Observable state for the request list view.
///
/// Manages loading, pagination, sorting, filtering, and voting.
/// All async work lives here — views only read state and call methods.
@Observable
@MainActor
public final class RequestListModel {

  // MARK: - Public State

  /// The currently loaded requests.
  public private(set) var requests: [Request] = []

  /// The request currently selected for detail view. Set to nil to dismiss.
  public var selectedRequest: Request?

  /// Whether the initial load or a filter change is in progress.
  public private(set) var isLoading = false

  /// The most recent error, if any.
  public private(set) var error: DifferentRequestsError?

  /// The current sort order.
  public var sort: SortOrder = .recent

  /// The current status filter. `nil` means all statuses.
  public var statusFilter: RequestStatus?

  /// Whether more pages are available.
  public private(set) var hasMore = false

  // MARK: - Private State

  private let client: DifferentRequestsClient
  private var cursor: String?

  // MARK: - Initialization

  /// Creates a request list model.
  /// - Parameter client: The DifferentRequests client to use for API calls.
  public init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Load the first page of requests, replacing any existing data.
  public func load() async {
    isLoading = true
    error = nil
    cursor = nil

    do {
      let result = try await client.listRequests(
        sort: sort,
        status: statusFilter,
        limit: 20,
        cursor: nil
      )
      requests = result.requests
      cursor = result.cursor
      hasMore = result.hasMore
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }

    isLoading = false
  }

  /// Load the next page of requests, appending to the existing list.
  public func loadMore() async {
    guard hasMore, !isLoading else { return }

    do {
      let result = try await client.listRequests(
        sort: sort,
        status: statusFilter,
        limit: 20,
        cursor: cursor
      )
      requests.append(contentsOf: result.requests)
      cursor = result.cursor
      hasMore = result.hasMore
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }
  }

  /// Pull-to-refresh: reload from the first page.
  public func refresh() async {
    await load()
  }

  // MARK: - Voting

  /// Vote on a request and refresh the list to reflect the new score.
  public func vote(requestId: String, value: VoteValue) async {
    do {
      try await client.vote(requestId: requestId, value: value)
      await refresh()
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }
  }

  // MARK: - Sort/Filter

  /// Change sort order and reload.
  public func changeSort(to newSort: SortOrder) async {
    sort = newSort
    await load()
  }

  /// Change status filter and reload.
  public func changeFilter(to newFilter: RequestStatus?) async {
    statusFilter = newFilter
    await load()
  }
}
