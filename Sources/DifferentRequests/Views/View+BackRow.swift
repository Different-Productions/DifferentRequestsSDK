import SwiftUI

extension View {

  /// Back at the top of this screen on macOS when it was pushed.
  func backRow() -> some View {
    modifier(BackRow())
  }
}
