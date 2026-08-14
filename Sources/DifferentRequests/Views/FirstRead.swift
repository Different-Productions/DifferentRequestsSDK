import SwiftUI

extension View {

  /// Reads a surface's first page when its store has not read one yet.
  ///
  /// Keyed on the store's own flag rather than left as a bare `task`, because the store outlives
  /// the screen: it belongs to the hub the host app holds, and the screen is a value SwiftUI
  /// throws away and builds again whenever anything above it redraws. A bare `task` fires once per
  /// appearance and would re-read a page the store already has, clearing it on the way. Keyed this
  /// way, the read is once per store rather than once per screen — and a store that has never read
  /// is noticed and read, however it came to be on screen.
  ///
  /// - Parameters:
  ///   - hasLoaded: Whether the store has finished a first read.
  ///   - read: Performs that read.
  func firstRead(hasLoaded: Bool, read: @escaping () async -> Void) -> some View {
    task(id: hasLoaded) {
      if hasLoaded { return }
      await read()
    }
  }
}
