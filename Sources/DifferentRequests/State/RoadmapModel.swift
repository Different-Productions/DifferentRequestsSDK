import Foundation
import SwiftUI

/// Observable state for the public roadmap board.
///
/// Loads the Pro-gated roadmap and groups it into ``RoadmapColumn``s (Planned,
/// In Progress, Shipped) for column display. Drives ``RoadmapView`` reactively
/// via `@Observable`.
///
/// ```swift
/// let model = RoadmapModel(client: client)
/// await model.load()
/// ```
@Observable
@MainActor
public final class RoadmapModel {

  /// The statuses that appear on the roadmap, in column display order.
  static let columnStatuses: [RequestStatus] = [.planned, .inProgress, .shipped]

  // MARK: - Public State

  /// The loaded roadmap, grouped into columns in ``columnStatuses`` order.
  /// Empty until ``load()`` completes.
  public private(set) var columns: [RoadmapColumn] = []

  /// Whether the initial load is in progress.
  public private(set) var isLoading = false

  /// The most recent error, if any. Check for
  /// ``DifferentRequestsError/paymentRequired(message:)`` to distinguish
  /// "this app isn't Pro" from a network or server failure.
  public private(set) var error: DifferentRequestsError?

  // MARK: - Private State

  private let client: DifferentRequestsClient

  // MARK: - Initialization

  /// Creates a roadmap model.
  /// - Parameter client: The DifferentRequests client to use for API calls.
  public init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Load the roadmap, replacing any existing data.
  public func load() async {
    isLoading = true
    error = nil

    do {
      let requests = try await client.listRoadmap()
      columns = RoadmapModel.group(requests)
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }

    isLoading = false
  }

  /// Group requests into columns by status, preserving the server's
  /// within-column ordering.
  /// - Parameter requests: The roadmap requests as returned by ``DifferentRequestsClient/listRoadmap()``.
  static func group(_ requests: [Request]) -> [RoadmapColumn] {
    columnStatuses.map { status in
      RoadmapColumn(status: status, requests: requests.filter { $0.status == status })
    }
  }
}
