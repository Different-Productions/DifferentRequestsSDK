import DifferentRequestsProtos
import SwiftUI

extension DRFontFamily {

  /// The system family this choice names. Nothing chosen, or a family this build does not know, is
  /// the system's default family.
  func fontDesign() -> Font.Design {
    switch self {
    case .default, .unspecified, .UNRECOGNIZED:
      return .default
    case .rounded:
      return .rounded
    case .serif:
      return .serif
    case .monospaced:
      return .monospaced
    }
  }
}
