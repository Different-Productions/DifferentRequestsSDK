import Foundation

/// Where a surface's read has got to, and what it found.
///
/// One value, because the state of a read is one fact. Spread across a loading flag, a
/// read-once flag, an error and the emptiness of a collection, it is sixteen combinations of
/// which four are real, and a view assembling those four one clause at a time is free to drop
/// any of them and still compile. The one that goes first is always the same: the surface that
/// read and found nothing, drawn as a blank page indistinguishable from one still reading.
///
/// The four a reader can be looking at are: nothing yet, a failure, nothing there, and something
/// there. There are six cases because two of the four are two situations that draw the same
/// picture and are not the same to the store — a read already running must not be started twice,
/// and a refresh must not blank the list it is refreshing, because the list owns the task doing
/// the refreshing and a list that disappears takes that task with it.
enum ReadState<Content> {

  /// Nothing has been asked for.
  case unread

  /// A read is in flight with nothing to show while it runs.
  case reading

  /// A read did not answer.
  ///
  /// The error is here for whoever is debugging. It is not what a reader is told: the contract
  /// states an `ApiError`'s message is written for a developer reading a log and may name
  /// internals, so the copy on screen is written by the view instead.
  case failed(any Error)

  /// A read answered and there is nothing there.
  case empty

  /// A read answered, and this is what it found.
  case loaded(Content)

  /// A read is in flight over content already on screen, which stays up while it runs.
  case refreshing(Content)
}

extension ReadState {

  /// Whether a read has finished, whatever it found.
  ///
  /// False only until the first answer arrives; a refresh does not make a surface unread again.
  /// This is what ``SwiftUI/View/firstRead(_:read:)`` keys its task on, so it must not change
  /// while a read is in flight — a task keyed on something that flips mid-read cancels the read
  /// that flipped it.
  var hasRead: Bool {
    switch self {
    case .unread, .reading:
      return false
    case .failed, .empty, .loaded, .refreshing:
      return true
    }
  }

  /// Whether a read is running, with or without something already on screen.
  ///
  /// What a `load()` checks before starting another one.
  var isReading: Bool {
    switch self {
    case .reading, .refreshing:
      return true
    case .unread, .failed, .empty, .loaded:
      return false
    }
  }

  /// What a read has found, or nil until one has found anything.
  ///
  /// Both states that hold something answer, not only the settled one. A surface renders the same
  /// thing for `loaded` and `refreshing`, so a store that reads only `loaded` refuses every write
  /// made during a refresh — and refuses it in silence, which is the failure this whole shape
  /// exists to make impossible.
  ///
  /// The surfaces holding a collection read ``held`` instead: "no rows" and "not read yet" are
  /// already two cases there, and a nil would be a third way to ask the same question.
  var content: Content? {
    switch self {
    case .unread, .reading, .failed, .empty:
      return nil
    case .loaded(let held), .refreshing(let held):
      return held
    }
  }

  /// The failure the last read ended in, for a host app that wants to log it or branch on its
  /// `DifferentRequestsError` case. Nil in every other state.
  var failure: (any Error)? {
    switch self {
    case .unread, .reading, .empty, .loaded, .refreshing:
      return nil
    case .failed(let error):
      return error
    }
  }

  /// The state to move to when a read starts: whatever is already held stays on screen for the
  /// length of it.
  var whileReading: ReadState<Content> {
    switch self {
    case .unread, .reading, .failed, .empty:
      return .reading
    case .loaded(let held), .refreshing(let held):
      return .refreshing(held)
    }
  }

  /// The state that holds `answer` without saying anything about whether a read is running.
  ///
  /// What a write's answer lands through. A write can answer while a refresh is still suspended,
  /// and landing it as `loaded` would clear the mark that says a read is in flight — after which
  /// the next thing to ask for one starts a second read over the top of the first.
  func holding(_ answer: Content) -> ReadState<Content> {
    switch self {
    case .reading, .refreshing:
      return .refreshing(answer)
    case .unread, .failed, .empty, .loaded:
      return .loaded(answer)
    }
  }

  /// The state a read that threw ends in.
  ///
  /// A server saying the thing is not there is answering rather than failing, and the two are
  /// different screens: someone who followed a link to a request that has since gone is owed
  /// "it is not here" rather than "check your connection", which would send them to retry a
  /// read that will never succeed.
  init(readFailure: any Error) {
    if let known = readFailure as? DifferentRequestsError, known.isNotFound {
      self = .empty
    } else {
      self = .failed(readFailure)
    }
  }
}
