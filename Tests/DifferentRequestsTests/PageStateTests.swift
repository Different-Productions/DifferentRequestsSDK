import Foundation
import Testing

@testable import DifferentRequests

/// A paged surface has three things to say about the page after the last row, and the third is
/// the one with nowhere else to go. A page that fails while a list is on screen cannot report
/// itself through the state that list is drawn from — a list on screen is what a paged view reads
/// as proof that nothing went wrong — so the failure has to be here, or the reader is left with a
/// spinner waiting on a page nothing will ask for again.
struct PageStateTests {

  @Test("The server leaves the cursor empty on the last page, and that is the whole rule")
  func theServerLeavesTheCursorEmptyOnTheLastPage() {
    #expect(PageState(nextCursor: "").isDone)
    #expect(PageState(nextCursor: "eyJvZmZzZXQiOjI1fQ").isDone == false)
  }

  @Test("A failed page is neither done nor reading, so the row under the list can say so")
  func aFailedPageIsNeitherDoneNorReading() {
    let more: PageState = .more
    #expect(more.isDone == false)
    #expect(more.isReading == false)
    #expect(more.failure == nil)

    let reading: PageState = .reading
    #expect(reading.isReading)
    #expect(reading.isDone == false)
    #expect(reading.failure == nil)

    let failed: PageState = .failed(URLError(.timedOut))
    #expect(failed.failure != nil)
    #expect(failed.isReading == false, "a failed page still claiming to be in flight spins forever")
    #expect(
      failed.isDone == false,
      "a failed page counted as done hides the row that offers to ask for it again"
    )

    let done: PageState = .done
    #expect(done.isDone)
    #expect(done.isReading == false)
    #expect(done.failure == nil)
  }
}
