import SwiftUI

extension View {

  /// Sets this view's text, and any symbol in it, in the text style `role` names.
  func textRole(_ role: TextRole) -> some View {
    font(role.font())
  }
}
