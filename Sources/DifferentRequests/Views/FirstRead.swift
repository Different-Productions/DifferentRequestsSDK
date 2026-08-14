import SwiftUI

extension View {

  /// Reads a surface's first page when its store has not read one yet.
  ///
  /// Keyed on the store's own state rather than left as a bare `task`, because the store outlives
  /// the screen: it belongs to the hub the host app holds, and the screen is a value SwiftUI
  /// throws away and builds again whenever anything above it redraws. A bare `task` fires once per
  /// appearance and would re-read a page the store already has, clearing it on the way. Keyed this
  /// way, the read is once per store rather than once per screen — and a store that has never read
  /// is noticed and read, however it came to be on screen.
  ///
  /// The key is ``ReadState/hasRead``, which is false only until the first answer arrives. It has
  /// to be something that does not move while the read is running: a `task(id:)` whose id changes
  /// mid-flight cancels the very read that changed it.
  ///
  /// - Parameters:
  ///   - state: Where the store's read has got to.
  ///   - read: Performs the read.
  func firstRead<Content>(
    _ state: ReadState<Content>,
    read: @escaping () async -> Void
  ) -> some View {
    task(id: state.hasRead) {
      if state.hasRead { return }
      await read()
    }
  }
}
