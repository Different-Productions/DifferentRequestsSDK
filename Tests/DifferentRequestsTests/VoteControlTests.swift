import Testing
@testable import DifferentRequests

@Suite("VoteControl vote resolution")
struct VoteControlTests {

  @Test("tapping up with no existing vote upvotes")
  func tapUpFromNoVote() {
    #expect(VoteControl.voteValue(currentVote: nil, tapping: .upvote) == .upvote)
  }

  @Test("tapping down with no existing vote downvotes")
  func tapDownFromNoVote() {
    #expect(VoteControl.voteValue(currentVote: nil, tapping: .downvote) == .downvote)
  }

  @Test("re-tapping the active upvote toggles it off")
  func retapUpvoteRemoves() {
    #expect(VoteControl.voteValue(currentVote: VoteValue.upvote.rawValue, tapping: .upvote) == .remove)
  }

  @Test("re-tapping the active downvote toggles it off")
  func retapDownvoteRemoves() {
    #expect(VoteControl.voteValue(currentVote: VoteValue.downvote.rawValue, tapping: .downvote) == .remove)
  }

  @Test("tapping up while downvoted switches to an upvote")
  func tapUpWhileDownvoted() {
    #expect(VoteControl.voteValue(currentVote: VoteValue.downvote.rawValue, tapping: .upvote) == .upvote)
  }

  @Test("tapping down while upvoted switches to a downvote")
  func tapDownWhileUpvoted() {
    #expect(VoteControl.voteValue(currentVote: VoteValue.upvote.rawValue, tapping: .downvote) == .downvote)
  }
}
