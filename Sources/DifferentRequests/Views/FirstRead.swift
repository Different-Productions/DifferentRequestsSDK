import SwiftUI

extension View {

  /// Reads a surface's first page when its store has not read one yet.
  ///
  /// Keyed on the store's own flag rather than left as a bare `task`, because a bare one fires
  /// once per view identity and these stores do not live that long: a SwiftUI view is rebuilt
  /// whenever whatever presents it redraws, the store it builds alongside itself is rebuilt with
  /// it, and the identity SwiftUI remembers is unchanged. Keyed this way, a store that has not
  /// read yet is noticed and read, however it came to be there.
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
