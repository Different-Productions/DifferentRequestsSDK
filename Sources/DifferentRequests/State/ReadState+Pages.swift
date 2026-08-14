import Foundation

/// What a paged surface does with its state, for the four that hold a collection.
///
/// The distinction between "read, and there is nothing" and "not read yet" is drawn once, here,
/// rather than at each surface — which is how it came to be drawn differently at each of them.
extension ReadState where Content: RangeReplaceableCollection {

  /// The state a first page lands in.
  init(page: Content) {
    if page.isEmpty {
      self = .empty
    } else {
      self = .loaded(page)
    }
  }

  /// Everything held right now, which is nothing at all until a read has answered.
  ///
  /// A store reads this to find the row a write is about. It is the collection itself rather than
  /// an optional, because "no rows" and "not read yet" are already the difference between two
  /// cases and re-stating it as a nil would give a caller a second way to ask.
  var held: Content {
    switch self {
    case .unread, .reading, .failed, .empty:
      return Content()
    case .loaded(let content), .refreshing(let content):
      return content
    }
  }

  /// The state a further page lands in: what was already held, then this.
  func appending(_ page: Content) -> ReadState<Content> {
    var joined = held
    joined.append(contentsOf: page)
    return ReadState(page: joined)
  }

  /// The state a write's answer lands in: the row it returned in place of the one held under the
  /// same id.
  ///
  /// Found by id rather than by an index taken before the write, because a reload can replace the
  /// whole collection while the write is suspended and an index from before that suspension
  /// addresses a different row or runs off the end. A row that is gone by then is left gone — the
  /// write landed, and the next page it appears in will say so.
  ///
  /// Lands through ``ReadState/holding(_:)``, so a write that answers during a refresh does not
  /// clear the mark saying a read is still in flight.
  func replacing<Row>(
    _ written: Row,
    identifiedBy id: (Row) -> String
  ) -> ReadState<Content> where Content == [Row] {
    var joined = held
    if let index = joined.firstIndex(where: { id($0) == id(written) }) {
      joined[index] = written
    }
    if joined.isEmpty {
      return .empty
    }
    return holding(joined)
  }
}
