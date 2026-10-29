import SwiftUI

extension TextRole {

  /// The system text style this role is set in.
  func font() -> Font {
    switch self {
    case .screenTitle:
      return .largeTitle.bold()
    case .requestTitle:
      return .title2.bold()
    case .rowTitle:
      return .headline
    case .reading, .unspecified, .UNRECOGNIZED:
      return .body
    case .supporting:
      return .subheadline
    case .meta:
      return .footnote
    }
  }
}
