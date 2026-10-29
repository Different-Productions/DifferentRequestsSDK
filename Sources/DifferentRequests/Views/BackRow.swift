import SwiftUI

/// On macOS, the standard Back symbol at the top-leading corner of a pushed screen, because a stack
/// inside a Mac sheet's tab draws no bar to hold one. Nothing on iOS, and nothing on a screen that
/// was not pushed.
struct BackRow: ViewModifier {

  @Environment(\.isPresented) private var isPresented

  func body(content: Content) -> some View {
    #if os(macOS)
    if isPresented {
      content
        .topRow(BackButtonRow())
        .sheetBarHidden()
    } else {
      content
        .sheetBarHidden()
    }
    #else
    content
    #endif
  }
}
