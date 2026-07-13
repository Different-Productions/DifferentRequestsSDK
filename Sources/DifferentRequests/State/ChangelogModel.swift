import Foundation
import SwiftUI

/// Observable state for the public changelog ("What's New").
///
/// Loads the Pro-gated, published changelog entries, most recent first, with
/// cursor pagination — unlike the roadmap board (a small curated set),
/// a changelog accumulates unboundedly over the product's life. Drives
/// ``ChangelogView`` reactively via `@Observable`.
///
/// ```swift
/// let model = ChangelogModel(client: client)
/// await model.load()
/// ```
@Observable
@MainActor
public final class ChangelogModel {

  // MARK: - Public State

  /// The loaded entries, most recent first.
  public private(set) var entries: [ChangelogEntry] = []

  /// Whether the initial load is in progress.
  public private(set) var isLoading = false

  /// Whether more pages are available.
  public private(set) var hasMore = false

  /// The most recent error, if any. Check for
  /// ``DifferentRequestsError/paymentRequired(message:)`` to distinguish
  /// "this app isn't Pro" from a network or server failure.
  public private(set) var error: DifferentRequestsError?

  // MARK: - Private State

  private let client: DifferentRequestsClient
  private var cursor: String?

  // MARK: - Initialization

  /// Creates a changelog model.
  /// - Parameter client: The DifferentRequests client to use for API calls.
  public init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Load the first page of entries, replacing any existing data.
  public func load() async {
    isLoading = true
    error = nil
    cursor = nil

    do {
      let result = try await client.listChangelog(limit: 20, cursor: nil)
      entries = result.entries
      cursor = result.cursor
      hasMore = result.hasMore
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }

    isLoading = false
  }

  /// Load the next page of entries, appending to the existing list.
  public func loadMore() async {
    guard hasMore, !isLoading else { return }

    do {
      let result = try await client.listChangelog(limit: 20, cursor: cursor)
      entries.append(contentsOf: result.entries)
      cursor = result.cursor
      hasMore = result.hasMore
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }
  }
}
