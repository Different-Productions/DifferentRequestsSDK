import SwiftUI

extension View {

  /// Reads a surface's first page when its store has not read one yet.
  ///
  /// Guarded on the store's own state rather than left as a bare `task`, because the store outlives
  /// the screen: it belongs to the hub the host app holds, and the screen is a value SwiftUI throws
  /// away and builds again whenever anything above it redraws. Without the guard the read would run
  /// again on every appearance and clear a page the store already has.
  ///
  /// **The guard is a guard and never an id.** `task(id:)` cancels its work when the id changes, and
  /// ``ReadState/hasRead`` changes the moment the first answer arrives — which is partway through a
  /// read that makes more than one call. `RequestDetailStore.load` reads the request, then its
  /// thread, then whether the app takes comments: keyed on `hasRead`, the first answer cancelled the
  /// other two, and the request's discussion sat under "Couldn't load the discussion" while the call
  /// log showed `ListComments 200`. A single-call surface never noticed, which is why it survived.
  ///
  /// - Parameters:
  ///   - state: Where the store's read has got to.
  ///   - read: Performs the read.
  func firstRead<Content>(
    _ state: ReadState<Content>,
    read: @escaping () async -> Void
  ) -> some View {
    task {
      if state.hasRead { return }
      await read()
    }
  }
}
