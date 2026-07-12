import Foundation
import SwiftUI

/// Observable state for a request's comment thread.
///
/// Manages loading, posting (with optimistic insert), and deleting comments
/// (with optimistic removal). Drives ``CommentsSection`` and
/// ``CommentComposer`` reactively via `@Observable`.
///
/// ```swift
/// let model = CommentsThreadModel(client: client, requestId: "request-123")
/// await model.load()
/// model.draftBody = "Great idea!"
/// await model.post()
/// ```
@Observable
@MainActor
public final class CommentsThreadModel {

  // MARK: - Public State

  /// The loaded comments, oldest first.
  public private(set) var comments: [Comment] = []

  /// Whether the initial load is in progress.
  public private(set) var isLoading = false

  /// Whether a comment post is in progress.
  public private(set) var isPosting = false

  /// Whether more pages are available.
  public private(set) var hasMore = false

  /// The most recent error, if any.
  public private(set) var error: DifferentRequestsError?

  /// The compose field's current text. Bind this to ``CommentComposer``'s text field.
  public var draftBody = ""

  /// Whether ``draftBody`` has enough content to post (server also validates 1-2000 chars).
  public var isDraftValid: Bool {
    !draftBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  // MARK: - Private State

  private let client: DifferentRequestsClient
  private let requestId: String
  private var cursor: String?
  private var currentUserId: String?

  // MARK: - Initialization

  /// Creates a comments thread model.
  /// - Parameters:
  ///   - client: The DifferentRequests client to use for API calls.
  ///   - requestId: The request whose comments this model manages.
  public init(client: DifferentRequestsClient, requestId: String) {
    self.client = client
    self.requestId = requestId
  }

  // MARK: - Loading

  /// Load the first page of comments, replacing any existing data.
  public func load() async {
    isLoading = true
    error = nil
    cursor = nil
    currentUserId = await client.currentUserId

    do {
      let result = try await client.listComments(requestId: requestId, limit: 20, cursor: nil)
      comments = result.comments
      cursor = result.cursor
      hasMore = result.hasMore
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }

    isLoading = false
  }

  /// Load the next page of comments, appending to the existing list.
  public func loadMore() async {
    guard hasMore, !isLoading else { return }

    do {
      let result = try await client.listComments(requestId: requestId, limit: 20, cursor: cursor)
      comments.append(contentsOf: result.comments)
      cursor = result.cursor
      hasMore = result.hasMore
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }
  }

  // MARK: - Ownership

  /// Whether the current authenticated user authored this comment.
  /// Drives whether a delete affordance is shown.
  public func isMine(_ comment: Comment) -> Bool {
    guard let currentUserId else { return false }
    return comment.authorId == currentUserId
  }

  // MARK: - Posting

  /// Post ``draftBody`` as a new comment. Requires authentication.
  ///
  /// Inserts an optimistic entry immediately, then replaces it with the
  /// server's response on success, or removes it and sets ``error`` on
  /// failure — the list never keeps a phantom entry. Clears ``draftBody``
  /// as soon as the optimistic entry is inserted.
  public func post() async {
    guard isDraftValid else { return }
    let trimmed = draftBody.trimmingCharacters(in: .whitespacesAndNewlines)

    guard let userId = await client.currentUserId,
          let displayName = await client.currentUserDisplayName else {
      error = .notAuthenticated
      return
    }
    currentUserId = userId

    error = nil
    isPosting = true
    draftBody = ""

    let optimisticId = "pending-\(UUID().uuidString)"
    let optimisticComment = Comment(
      id: optimisticId,
      requestId: requestId,
      appId: "",
      authorId: userId,
      authorDisplayName: displayName,
      isOfficial: false,
      body: trimmed,
      hidden: false,
      createdAt: .now
    )
    comments.append(optimisticComment)

    do {
      let created = try await client.postComment(requestId: requestId, body: trimmed)
      if let index = comments.firstIndex(where: { $0.id == optimisticId }) {
        comments[index] = created
      }
    } catch let err as DifferentRequestsError {
      comments.removeAll { $0.id == optimisticId }
      error = err
      draftBody = trimmed
    } catch {
      comments.removeAll { $0.id == optimisticId }
      self.error = .networkError(underlying: error)
      draftBody = trimmed
    }

    isPosting = false
  }

  // MARK: - Deleting

  /// Delete a comment authored by the current user.
  ///
  /// Removes the comment from the list immediately, then rolls back
  /// (re-inserts at its original position) and sets ``error`` if the
  /// server rejects the delete.
  /// - Parameter commentId: The comment to delete.
  public func delete(commentId: String) async {
    guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }
    let removed = comments[index]
    comments.remove(at: index)
    error = nil

    do {
      try await client.deleteComment(requestId: requestId, commentId: commentId)
    } catch let err as DifferentRequestsError {
      comments.insert(removed, at: index)
      error = err
    } catch {
      comments.insert(removed, at: index)
      self.error = .networkError(underlying: error)
    }
  }
}
