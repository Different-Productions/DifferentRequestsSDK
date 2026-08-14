import Foundation

/// What a surface's last write is doing, or what it did instead.
///
/// One value, because both halves of a write are the same fact and a surface needs both: what to
/// disable, and what to say. Held apart, the failure half is a property a store can assign and
/// every view can ignore while still compiling — which is what a write failing in silence is
/// made of. Someone taps, the control does not move, and nothing on screen says why.
///
/// A failure stays here until the next write starts or someone acknowledges it. It is not cleared
/// by time or by a redraw: it has to outlive the moment it happened in, because the moment it
/// happened in is the one the reader was not looking at.
enum WriteState {

  /// Nothing is being written and nothing failed.
  case idle

  /// A write is in flight. One at a time per surface: two votes racing would settle on whichever
  /// answer arrived last rather than on the last tap.
  case writing(WriteAttempt)

  /// The last write did not land.
  case failed(WriteFailure)
}

extension WriteState {

  /// Whether a write is in flight. What a store checks before starting another one, and what the
  /// controls on a surface disable themselves from.
  var isWriting: Bool {
    switch self {
    case .writing:
      return true
    case .idle, .failed:
      return false
    }
  }

  /// The failure to tell the reader about, or nil when there is nothing to say.
  var failure: WriteFailure? {
    switch self {
    case .idle, .writing:
      return nil
    case .failed(let failure):
      return failure
    }
  }
}
