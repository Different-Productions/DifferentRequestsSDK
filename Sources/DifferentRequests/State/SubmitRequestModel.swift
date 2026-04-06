import Foundation
import SwiftUI

/// Observable state for the submit request form.
///
/// Manages form fields, validation, duplicate search, and submission.
/// Drives ``SubmitRequestView`` reactively via `@Observable`.
///
/// ```swift
/// let model = SubmitRequestModel(client: client)
/// model.title = "Dark mode"
/// await model.searchSimilar()
/// if let request = await model.submit() {
///   print("Created: \(request.id)")
/// }
/// ```
@Observable
@MainActor
public final class SubmitRequestModel {

  // MARK: - Public State

  /// The request title field.
  public var title = ""

  /// The request body field.
  public var body = ""

  /// Similar requests found by searching the title.
  public private(set) var similarRequests: [Request] = []

  /// Whether a similar-request search is in progress.
  public private(set) var isSearching = false

  /// Whether submission is in progress.
  public private(set) var isSubmitting = false

  /// The most recent error, if any.
  public private(set) var error: DifferentRequestsError?

  /// Whether the form has enough data to submit.
  public var isValid: Bool {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmedTitle.isEmpty && !trimmedBody.isEmpty
  }

  // MARK: - Private State

  private let client: DifferentRequestsClient

  // MARK: - Initialization

  /// Creates a submit request model.
  /// - Parameter client: The DifferentRequests client to use for API calls.
  public init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Similar Search

  /// Search for requests with similar titles.
  ///
  /// Call this after a debounce when the title field changes.
  /// Only searches if the title has at least 3 characters.
  public func searchSimilar() async {
    let query = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard query.count >= 3 else {
      similarRequests = []
      return
    }

    isSearching = true

    do {
      similarRequests = try await client.searchRequests(query: query, limit: 5)
    } catch {
      similarRequests = []
    }

    isSearching = false
  }

  // MARK: - Submission

  /// Submit the request. Returns the created request on success, `nil` on failure.
  ///
  /// Sets ``error`` if submission fails. Sets ``isSubmitting`` during the operation.
  /// - Returns: The newly created request, or `nil` if submission failed.
  public func submit() async -> Request? {
    guard isValid else { return nil }

    isSubmitting = true
    error = nil

    do {
      let request = try await client.submitRequest(
        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
        body: body.trimmingCharacters(in: .whitespacesAndNewlines)
      )
      isSubmitting = false
      return request
    } catch let err as DifferentRequestsError {
      error = err
      isSubmitting = false
      return nil
    } catch {
      self.error = .networkError(underlying: error)
      isSubmitting = false
      return nil
    }
  }
}
