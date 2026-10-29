import SwiftUI

#if os(macOS)
  import AppKit

  /// Hands each edit in ``BoardSearchField`` to the board as its query.
  @MainActor
  final class BoardSearchFieldDelegate: NSObject, NSSearchFieldDelegate {

    /// What the typed text narrows.
    let board: BoardStore

    init(board: BoardStore) {
      self.board = board
    }

    func controlTextDidChange(_ notification: Notification) {
      if let field = notification.object as? NSSearchField {
        board.board.query = field.stringValue
      }
    }
  }
#endif
