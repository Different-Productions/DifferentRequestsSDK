import SwiftUI

extension View {

  /// No navigation bar above this screen inside the Mac sheet.
  func sheetBarHidden() -> some View {
    modifier(SheetBarHidden())
  }
}
