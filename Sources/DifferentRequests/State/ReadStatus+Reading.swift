import Foundation

/// Where a surface's read has got to. What it found is held beside this on the store, so the four
/// pictures a reader can be looking at come from the two together: nothing yet, a failure, nothing
/// there, and something there.
///
/// A read already running must not be started twice, and a refresh must not blank the list it is
/// refreshing, because the list owns the task doing the refreshing and a list that disappears takes
/// that task with it. So a read in flight leaves whatever is held where it is.
extension ReadStatus {

  /// The status a read that threw ends in. The store clears what it held.
  ///
  /// A server saying the thing is not there is answering rather than failing: someone who followed
  /// a link to a request that has since gone is owed "it is not here" rather than "check your
  /// connection". A read that was called off lands back where it started, unset, so the next `.task`
  /// reads again on its own and the screen says it is still reading until then.
  init(readFailure: any Error) {
    self.init()
    if let known = readFailure as? DifferentRequestsError, known.isNotFound() {
      state = .loaded(ReadAnswered())
    } else if readFailure.isCancellation() == false {
      state = .failed(ReadTrouble(error: readFailure))
    }
  }

  /// Whether a read is running, with or without something already on screen. What a `load()`
  /// checks before starting another one.
  func isReading() -> Bool {
    switch state {
    case .reading:
      return true
    case .none, .failed, .loaded:
      return false
    }
  }

  /// Whether a read has finished, whatever it found, given whether the store `holdsContent`.
  ///
  /// False only until the first answer arrives; a refresh over held content does not make a surface
  /// unread again. A guard keyed on this must never be a task's id: it changes the moment the first
  /// answer arrives, and a task keyed on something that flips mid-read cancels the read that flipped
  /// it.
  func hasRead(holdsContent: Bool) -> Bool {
    switch state {
    case .none:
      return false
    case .reading:
      return holdsContent
    case .failed, .loaded:
      return true
    }
  }

  /// The status a write's answer lands in.
  ///
  /// A write can answer while a refresh is still suspended, and landing it as answered would clear
  /// the mark that says a read is in flight, after which the next thing to ask for one starts a
  /// second read over the top of the first.
  func afterWrite() -> ReadStatus {
    switch state {
    case .reading:
      return self
    case .none, .failed, .loaded:
      var landed = ReadStatus()
      landed.state = .loaded(ReadAnswered())
      return landed
    }
  }
}
