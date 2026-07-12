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

  @Test("currentUserId is nil before authenticating")
  func currentUserIdBeforeAuth() async {
    let client = DifferentRequestsClient(apiKey: "test-key")
    let userId = await client.currentUserId
    #expect(userId == nil)
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

@Suite("DifferentRequestsError")
struct ErrorTests {

  @Test("Error cases are distinct")
  func errorCases() {
    let errors: [DifferentRequestsError] = [
      .notAuthenticated,
      .notFound(message: "Not found"),
      .forbidden(message: "Forbidden"),
      .validationError(message: "Invalid"),
      .rateLimited(retryAfter: 60),
      .serverError(statusCode: 500, message: "Internal"),
      .merged(targetId: "abc"),
    ]
    #expect(errors.count == 7)
  }
}
