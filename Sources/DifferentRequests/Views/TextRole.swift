import SwiftUI

/// What a piece of text is for, which decides the system text style it is set in.
///
/// Every role is a built-in text style, so all of them follow Dynamic Type.
enum TextRole {

  /// A screen's title. Large Title.
  case screenTitle

  /// A request's title on its own screen. Title 2.
  case requestTitle

  /// A row's title, a heading, a button's label. Headline.
  case rowTitle

  /// Anything read at length: comments, notes, fields. Body.
  case reading

  /// One supporting line under a title. Subheadline.
  case supporting

  /// Status, counts, age, help under a field. Footnote.
  case meta

  /// The system text style this role is set in.
  func font() -> Font {
    switch self {
    case .screenTitle:
      return .largeTitle.bold()
    case .requestTitle:
      return .title2.bold()
    case .rowTitle:
      return .headline
    case .reading:
      return .body
    case .supporting:
      return .subheadline
    case .meta:
      return .footnote
    }
  }
}
