import Foundation

/// What a board with nothing on it says, in the host app's own words.
///
/// Set once on ``DifferentRequestsHub``. Drawn only on Pro, as part of the app's own look; on Free
/// the SDK's words in ``standard`` are drawn whatever is set here. A field left empty is filled from
/// ``standard``. Only the board with nothing narrowing it reads this: a search or a filter that finds
/// nothing describes what the person did, and keeps the SDK's words.
///
/// ```swift
/// EmptyBoard(
///   symbol: "leaf",
///   title: "What would help your practice?",
///   message: "Tell us what would make your sessions calmer. Others can add their vote.",
///   button: "Share an idea"
/// )
/// ```
public struct EmptyBoard: Sendable, Equatable {

  /// The SDK's own words, for an app that sets none.
  public static let standard = EmptyBoard(
    symbol: "lightbulb.max",
    title: String(localized: "What should we build?", bundle: .module, comment: "Heading on a request board with no requests yet"),
    message: String(
      localized: "Nobody has asked for anything yet. Tell us what you want and everyone can vote on it.",
      bundle: .module,
      comment: "Message on a request board with no requests yet"
    ),
    button: String(localized: "New request", bundle: .module, comment: "Button that opens the form for a new feature request")
  )

  /// An SF Symbol name, drawn above the title.
  public let symbol: String

  /// The heading.
  public let title: String

  /// The sentence under the heading.
  public let message: String

  /// The words on the button. It still opens the composer.
  public let button: String

  /// - Parameters:
  ///   - symbol: An SF Symbol name, drawn above the title.
  ///   - title: The heading.
  ///   - message: The sentence under the heading.
  ///   - button: The words on the button that opens the composer.
  public init(symbol: String, title: String, message: String, button: String) {
    self.symbol = symbol
    self.title = title
    self.message = message
    self.button = button
  }

  /// These words, with any field left empty taken from ``standard``.
  var filledIn: EmptyBoard {
    EmptyBoard(
      symbol: symbol.isEmpty ? Self.standard.symbol : symbol,
      title: title.isEmpty ? Self.standard.title : title,
      message: message.isEmpty ? Self.standard.message : message,
      button: button.isEmpty ? Self.standard.button : button
    )
  }
}
