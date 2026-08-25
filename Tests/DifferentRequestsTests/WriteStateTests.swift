import DifferentRequestsProtos
import Foundation
import Testing

@testable import DifferentRequests

/// A write has two halves a surface needs — what to disable, and what to say — and holding them
/// apart is what lets a store publish a refusal every view can ignore while still compiling. One
/// value is what makes ignoring it deliberate rather than easy.
///
/// These walk the value: that a failure is readable, that every write has something to say, and
/// that what it says is never the server's own message.
struct WriteStateTests {

  @Test("Every write has something to say, and no two of them say the same thing")
  func everyWriteHasSomethingToSay() {
    // Walked from the generated case list rather than a list written here, so a write added to
    // the enum is covered by being declared instead of by anyone remembering to add it.
    var seen: Set<String> = []
    for attempt in WriteAttempt.allCases {
      let sentence = attempt.failureMessage
      #expect(sentence.isEmpty == false, "\(attempt) fails in silence")
      #expect(
        seen.contains(sentence) == false,
        "\(attempt) says the same thing as another write, so a reader cannot tell which failed"
      )
      seen.insert(sentence)
    }
    #expect(seen.count == WriteAttempt.allCases.count)
  }

  @Test("A failure is readable and a write in flight is not")
  func aFailureIsReadableAndAWriteInFlightIsNot() {
    let idle: WriteState = .idle
    #expect(idle.isWriting == false)
    #expect(idle.failure == nil)

    let running: WriteState = .writing(.vote)
    #expect(running.isWriting)
    #expect(
      running.failure == nil,
      "a write in flight showing the last failure tells someone it failed before it has"
    )

    let failed: WriteState = .failed(
      WriteFailure(attempt: .comment, error: URLError(.notConnectedToInternet))
    )
    #expect(failed.isWriting == false, "a failed write still holding the controls inert hangs them")
    #expect(failed.failure != nil, "a refused write with nothing to read is a refusal in silence")
    #expect(failed.failure?.attempt == .comment)
  }

  @Test("The sentence a reader gets is never the server's")
  func theSentenceIsNeverTheServers() {
    // The contract states an ApiError's message is written for whoever is debugging and may name
    // internals. This one does.
    var refused = DRApiError()
    refused.reason = .internalFailure(DRInternalFailure())
    refused.message = "vote_upsert failed: pg_conn refused at shard 4"

    let failure = WriteFailure(attempt: .vote, error: DifferentRequestsError.api(refused))

    #expect(failure.message == WriteAttempt.vote.failureMessage)
    #expect(failure.message.contains("pg_conn") == false)
    #expect(failure.message.contains("shard") == false)

    // And the error is still there, for whoever is debugging.
    let carried = failure.error as? DifferentRequestsError
    #expect(carried != nil, "the failure threw away the thing a developer needs")
  }

  @Test("A vote and an un-vote are different writes, because they read differently when they fail")
  func aVoteAndAnUnvoteAreDifferentWrites() {
    #expect(WriteAttempt.vote.failureMessage != WriteAttempt.clearVote.failureMessage)
    #expect(WriteAttempt.follow.failureMessage != WriteAttempt.unfollow.failureMessage)
    #expect(WriteAttempt.markRead.failureMessage != WriteAttempt.markEverythingRead.failureMessage)
  }
}
