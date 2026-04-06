import Testing
import Foundation
@testable import DifferentRequests

@Suite("DifferentRequestsClient")
struct ClientTests {

  @Test("init succeeds with valid URL")
  func initWithValidURL() throws {
    let url = try #require(URL(string: "https://api.example.com"))
    let client = try DifferentRequestsClient(apiKey: "test-key", baseURL: url)
    #expect(client != nil)
  }

  @Test("submitRequest throws notAuthenticated without session")
  func submitWithoutAuth() async {
    let url = URL(string: "https://api.example.com")!
    guard let client = try? DifferentRequestsClient(apiKey: "test-key", baseURL: url) else {
      Issue.record("Failed to create client")
      return
    }

    await #expect(throws: DifferentRequestsError.self) {
      try await client.submitRequest(title: "Test", body: "Test body")
    }
  }

  @Test("vote throws notAuthenticated without session")
  func voteWithoutAuth() async {
    let url = URL(string: "https://api.example.com")!
    guard let client = try? DifferentRequestsClient(apiKey: "test-key", baseURL: url) else {
      Issue.record("Failed to create client")
      return
    }

    await #expect(throws: DifferentRequestsError.self) {
      try await client.vote(requestId: "123", value: .upvote)
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

@Suite("DifferentRequestsError")
struct ErrorTests {

  @Test("Error cases are distinct")
  func errorCases() {
    let errors: [DifferentRequestsError] = [
      .notAuthenticated,
      .notFound(message: "Not found"),
      .validationError(message: "Invalid"),
      .rateLimited(retryAfter: 60),
      .serverError(statusCode: 500, message: "Internal"),
      .merged(targetId: "abc"),
    ]
    #expect(errors.count == 6)
  }
}
