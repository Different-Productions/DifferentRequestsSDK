import Foundation
import SwiftUI

/// Observable state for a user's in-app notification inbox.
///
/// Manages loading, pagination, mark-as-read (with optimistic update), and
/// the unread count for a badge. Drives ``NotificationCenterView``
/// reactively via `@Observable`.
///
/// ```swift
/// let model = NotificationCenterModel(client: client)
/// await model.load()
/// await model.refreshUnreadCount()
/// ```
@Observable
@MainActor
public final class NotificationCenterModel {

  // MARK: - Public State

  /// The loaded notifications, most recent first.
  public private(set) var notifications: [AppNotification] = []

  /// Whether the initial load is in progress.
  public private(set) var isLoading = false

  /// Whether more pages are available.
  public private(set) var hasMore = false

  /// The caller's unread notification count, or `nil` until
  /// ``refreshUnreadCount()`` completes. Bind this to a tab badge or bell icon.
  public private(set) var unreadCount: Int?

  /// The most recent error, if any.
  public private(set) var error: DifferentRequestsError?

  // MARK: - Private State

  private let client: DifferentRequestsClient
  private var cursor: String?

  // MARK: - Initialization

  /// Creates a notification center model.
  /// - Parameter client: The DifferentRequests client to use for API calls.
  public init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Load the first page of notifications, replacing any existing data.
  public func load() async {
    isLoading = true
    error = nil
    cursor = nil

    do {
      let result = try await client.listNotifications(limit: 20, cursor: nil)
      notifications = result.notifications
      cursor = result.cursor
      hasMore = result.hasMore
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }

    isLoading = false
  }

  /// Load the next page of notifications, appending to the existing list.
  public func loadMore() async {
    guard hasMore, !isLoading else { return }

    do {
      let result = try await client.listNotifications(limit: 20, cursor: cursor)
      notifications.append(contentsOf: result.notifications)
      cursor = result.cursor
      hasMore = result.hasMore
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }
  }

  /// Refresh ``unreadCount``. Call on view appear and after ``markRead(id:)``.
  public func refreshUnreadCount() async {
    do {
      unreadCount = try await client.unreadNotificationCount()
    } catch let err as DifferentRequestsError {
      error = err
    } catch {
      self.error = .networkError(underlying: error)
    }
  }

  // MARK: - Marking Read

  /// Mark one notification read. Requires authentication.
  ///
  /// Updates the row and decrements ``unreadCount`` immediately, then rolls
  /// both back and sets ``error`` if the server rejects the change — the
  /// same optimistic-update-with-rollback shape as ``FollowModel/toggle()``.
  /// A no-op if the notification is already marked read locally.
  public func markRead(id: String) async {
    guard let index = notifications.firstIndex(where: { $0.id == id }), !notifications[index].read else { return }

    let previous = notifications[index]
    notifications[index] = AppNotification(
      id: previous.id,
      requestId: previous.requestId,
      type: previous.type,
      status: previous.status,
      commentId: previous.commentId,
      read: true,
      createdAt: previous.createdAt
    )
    let previousUnreadCount = unreadCount
    if let previousUnreadCount {
      unreadCount = max(0, previousUnreadCount - 1)
    }
    error = nil

    do {
      _ = try await client.markNotificationRead(id: id)
    } catch let err as DifferentRequestsError {
      notifications[index] = previous
      unreadCount = previousUnreadCount
      error = err
    } catch {
      notifications[index] = previous
      unreadCount = previousUnreadCount
      self.error = .networkError(underlying: error)
    }
  }
}
