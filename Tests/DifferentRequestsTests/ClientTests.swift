import Testing
import Foundation
@testable import DifferentRequests

@Suite("DifferentRequestsClient")
struct ClientTests {

  @Test("init succeeds")
  func initSucceeds() {
    let client = DifferentRequestsClient(apiKey: "test-key")
    #expect(client != nil)
  }

  @Test("submitRequest throws notAuthenticated without session")
  func submitWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.submitRequest(title: "Test", body: "Test body")
    }
  }

  @Test("vote throws notAuthenticated without session")
  func voteWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.vote(requestId: "123", value: .upvote)
    }
  }

  @Test("postComment throws notAuthenticated without session")
  func postCommentWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.postComment(requestId: "123", body: "Great idea!")
    }
  }

  @Test("deleteComment throws notAuthenticated without session")
  func deleteCommentWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.deleteComment(requestId: "123", commentId: "456")
    }
  }

  @Test("registerDevice throws notAuthenticated without session")
  func registerDeviceWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")
    let tokenData = Data(repeating: 0xAB, count: 32)

    await #expect(throws: DifferentRequestsError.self) {
      try await client.registerDevice(tokenData: tokenData)
    }
  }

  @Test("unregisterDevice throws notAuthenticated without session")
  func unregisterDeviceWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")
    let tokenData = Data(repeating: 0xAB, count: 32)

    await #expect(throws: DifferentRequestsError.self) {
      try await client.unregisterDevice(tokenData: tokenData)
    }
  }

  @Test("follow throws notAuthenticated without session")
  func followWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.follow(requestId: "123")
    }
  }

  @Test("unfollow throws notAuthenticated without session")
  func unfollowWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.unfollow(requestId: "123")
    }
  }

  @Test("listFollowedRequests throws notAuthenticated without session")
  func listFollowedRequestsWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.listFollowedRequests()
    }
  }

  @Test("currentUserId is nil before authenticating")
  func currentUserIdBeforeAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")
    let userId = await client.currentUserId
    #expect(userId == nil)
  }

  @Test("listNotifications throws notAuthenticated without session")
  func listNotificationsWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.listNotifications()
    }
  }

  @Test("unreadNotificationCount throws notAuthenticated without session")
  func unreadNotificationCountWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.unreadNotificationCount()
    }
  }

  @Test("markNotificationRead throws notAuthenticated without session")
  func markNotificationReadWithoutAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")

    await #expect(throws: DifferentRequestsError.self) {
      try await client.markNotificationRead(id: "notif-1")
    }
  }
}

@Suite("Models")
struct ModelTests {

  @Test("SortOrder raw values match API")
  func sortOrderRawValues() {
    #expect(SortOrder.recent.rawValue == "recent")
    #expect(SortOrder.top.rawValue == "top")
  }

  @Test("RequestStatus raw values match API")
  func requestStatusRawValues() {
    #expect(RequestStatus.open.rawValue == "open")
    #expect(RequestStatus.planned.rawValue == "planned")
    #expect(RequestStatus.inProgress.rawValue == "in_progress")
    #expect(RequestStatus.shipped.rawValue == "shipped")
    #expect(RequestStatus.declined.rawValue == "declined")
  }

  @Test("RequestSource raw values match API")
  func requestSourceRawValues() {
    #expect(RequestSource.sdk.rawValue == "sdk")
    #expect(RequestSource.console.rawValue == "console")
  }

  @Test("VoteValue raw values match API")
  func voteValueRawValues() {
    #expect(VoteValue.upvote.rawValue == 1)
    #expect(VoteValue.downvote.rawValue == -1)
    #expect(VoteValue.remove.rawValue == 0)
  }
}

@Suite("CommentsThreadModel")
@MainActor
struct CommentsThreadModelTests {

  @Test("isDraftValid is false for blank or whitespace-only text")
  func isDraftValidBlank() {
    let model = CommentsThreadModel(client: DifferentRequestsClient(apiKey: "test-key"), requestId: "req-1")
    model.draftBody = ""
    #expect(!model.isDraftValid)
    model.draftBody = "   \n  "
    #expect(!model.isDraftValid)
  }

  @Test("isDraftValid is true for non-blank text")
  func isDraftValidNonBlank() {
    let model = CommentsThreadModel(client: DifferentRequestsClient(apiKey: "test-key"), requestId: "req-1")
    model.draftBody = "Great idea!"
    #expect(model.isDraftValid)
  }

  @Test("isMine is false before authenticating")
  func isMineWithoutAuth() {
    let model = CommentsThreadModel(client: DifferentRequestsClient(apiKey: "test-key"), requestId: "req-1")
    let comment = Comment(
      id: "c1",
      requestId: "req-1",
      appId: "app-1",
      authorId: "user-1",
      authorDisplayName: "Jane",
      isOfficial: false,
      body: "Hello",
      hidden: false,
      createdAt: .now
    )
    #expect(!model.isMine(comment))
  }
}

@Suite("FollowModel")
@MainActor
struct FollowModelTests {

  @Test("starts with the given initial follow state and no known follower count")
  func initialState() {
    let model = FollowModel(client: DifferentRequestsClient(apiKey: "test-key"), requestId: "req-1", isFollowing: true)
    #expect(model.isFollowing)
    #expect(model.followerCount == nil)
    #expect(model.error == nil)
  }

  @Test("defaults to not following")
  func defaultsToNotFollowing() {
    let model = FollowModel(client: DifferentRequestsClient(apiKey: "test-key"), requestId: "req-1")
    #expect(!model.isFollowing)
  }

  @Test("toggle without a session rolls back and surfaces notAuthenticated")
  func toggleWithoutAuthRollsBack() async {
    let model = FollowModel(client: DifferentRequestsClient(apiKey: "test-key"), requestId: "req-1", isFollowing: false)
    await model.toggle()
    #expect(!model.isFollowing)
    #expect(model.error != nil)
  }
}

@Suite("NotificationCenterModel")
@MainActor
struct NotificationCenterModelTests {

  @Test("starts empty with no known unread count")
  func initialState() {
    let model = NotificationCenterModel(client: DifferentRequestsClient(apiKey: "test-key"))
    #expect(model.notifications.isEmpty)
    #expect(model.unreadCount == nil)
    #expect(!model.hasMore)
    #expect(model.error == nil)
  }

  @Test("markRead on an unknown id is a no-op")
  func markReadUnknownIdIsNoOp() async {
    let model = NotificationCenterModel(client: DifferentRequestsClient(apiKey: "test-key"))
    await model.markRead(id: "does-not-exist")
    #expect(model.notifications.isEmpty)
    #expect(model.error == nil)
  }

  @Test("refreshUnreadCount without a session surfaces notAuthenticated")
  func refreshUnreadCountWithoutAuth() async {
    let model = NotificationCenterModel(client: DifferentRequestsClient(apiKey: "test-key"))
    await model.refreshUnreadCount()
    #expect(model.unreadCount == nil)
    #expect(model.error != nil)
  }
}

@Suite("DifferentRequestsError")
struct ErrorTests {

  @Test("Error cases are distinct")
  func errorCases() {
    let errors: [DifferentRequestsError] = [
      .notAuthenticated,
      .notFound(message: "Not found"),
      .forbidden(message: "Forbidden"),
      .paymentRequired(message: "Payment required"),
      .validationError(message: "Invalid"),
      .rateLimited(retryAfter: 60),
      .serverError(statusCode: 500, message: "Internal"),
      .merged(targetId: "abc"),
    ]
    #expect(errors.count == 8)
  }

  @Test("paymentRequired surfaces the server's message")
  func paymentRequiredDescription() {
    let error = DifferentRequestsError.paymentRequired(message: "Roadmap requires the Pro plan")
    #expect(error.errorDescription == "Roadmap requires the Pro plan")
  }
}

@Suite("RoadmapModel")
@MainActor
struct RoadmapModelTests {

  @Test("starts empty with no error")
  func initialState() {
    let model = RoadmapModel(client: DifferentRequestsClient(apiKey: "test-key"))
    #expect(model.columns.isEmpty)
    #expect(!model.isLoading)
    #expect(model.error == nil)
  }

  @Test("groups requests by status in Planned, In Progress, Shipped column order")
  func groupOrdersColumnsByStatus() {
    let planned = makeRequest(id: "1", status: .planned)
    let inProgress = makeRequest(id: "2", status: .inProgress)
    let shipped = makeRequest(id: "3", status: .shipped)

    let columns = RoadmapModel.group([shipped, planned, inProgress])

    #expect(columns.map(\.status) == [.planned, .inProgress, .shipped])
    #expect(columns[0].requests.map(\.id) == ["1"])
    #expect(columns[1].requests.map(\.id) == ["2"])
    #expect(columns[2].requests.map(\.id) == ["3"])
  }

  @Test("group preserves server order within a column")
  func groupPreservesServerOrderWithinColumn() {
    let pinned = makeRequest(id: "pinned", status: .planned, roadmapPinned: true, roadmapOrder: 5)
    let ordered = makeRequest(id: "ordered", status: .planned, roadmapPinned: false, roadmapOrder: 1)

    let columns = RoadmapModel.group([pinned, ordered])

    #expect(columns[0].requests.map(\.id) == ["pinned", "ordered"])
  }

  @Test("group drops statuses that never appear on the roadmap")
  func groupExcludesNonRoadmapStatuses() {
    let open = makeRequest(id: "1", status: .open)
    let declined = makeRequest(id: "2", status: .declined)

    let columns = RoadmapModel.group([open, declined])

    #expect(columns.allSatisfy { $0.requests.isEmpty })
  }

  private func makeRequest(
    id: String,
    status: RequestStatus,
    roadmapPinned: Bool,
    roadmapOrder: Int
  ) -> Request {
    Request(
      id: id,
      appId: "app-1",
      authorId: "user-1",
      title: "Title",
      body: "Body",
      status: status,
      source: .sdk,
      score: 0,
      myVote: nil,
      roadmapPinned: roadmapPinned,
      roadmapOrder: roadmapOrder,
      roadmapVisible: true,
      mergedIntoId: nil,
      declineReason: nil,
      declineReasonId: nil,
      declineReasonLabel: nil,
      authorDisplayName: "Jane",
      authorExternalUserId: nil,
      authorAvatarUrl: nil,
      createdAt: .now,
      updatedAt: .now
    )
  }

  private func makeRequest(id: String, status: RequestStatus) -> Request {
    makeRequest(id: id, status: status, roadmapPinned: false, roadmapOrder: 0)
  }
}
