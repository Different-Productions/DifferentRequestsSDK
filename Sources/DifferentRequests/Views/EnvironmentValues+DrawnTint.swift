import SwiftUI

extension EnvironmentValues {

  /// The tint the SDK draws with, as ``WornLook`` set it: the one ``ColorRole/onTint`` measures.
  ///
  /// `Color.accentColor` is not it on macOS, where it resolves to the accent color chosen in System
  /// Settings rather than the tint set on the view.
  @Entry var drawnTint = DrawnTint()
}
