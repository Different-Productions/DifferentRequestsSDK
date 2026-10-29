import SwiftUI

#if os(macOS)
  import AppKit

  /// The Mac's own search field over the board, writing what is typed to the board's query.
  struct BoardSearchField: NSViewRepresentable {

    /// What the typed text narrows.
    let board: BoardStore

    func makeNSView(context: Context) -> NSSearchField {
      let field = NSSearchField(string: board.board.query)
      field.placeholderString = String(
        localized: "Search Requests",
        bundle: .module,
        comment: "Placeholder in the Mac request board's search field"
      )
      field.delegate = context.coordinator
      return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
      if field.stringValue != board.board.query {
        field.stringValue = board.board.query
      }
    }

    func makeCoordinator() -> BoardSearchFieldDelegate {
      BoardSearchFieldDelegate(board: board)
    }
  }
#endif
