import Foundation

extension Error {

  /// Whether this is a read that was called off rather than one that failed.
  ///
  /// SwiftUI cancels a `.task` when the view it belongs to goes away or its id changes, and a
  /// redraw of whatever is above a screen is enough to do it. The read stops mid-flight and throws,
  /// even though the server answered — which is why a request's discussion could sit under "Couldn't
  /// load the discussion. Try Again" while the call log showed `ListComments 200`.
  ///
  /// Cancellation means nobody is waiting for the answer any more. It says nothing about whether the
  /// answer was available, so it is not something to show a reader and not something to offer them a
  /// retry for: the screen that comes next reads again on its own.
  ///
  /// Both shapes are checked. Swift's own `CancellationError` is thrown by structured concurrency,
  /// and `URLSession` throws `URLError.cancelled` instead — and the client wraps whatever the
  /// session threw, so the wrapper is unwrapped here rather than at each caller.
  var isCancellation: Bool {
    if self is CancellationError {
      return true
    }
    if let url = self as? URLError, url.code == .cancelled {
      return true
    }
    if let known = self as? DifferentRequestsError, case .networkError(let underlying) = known {
      return underlying.isCancellation
    }
    return false
  }
}
