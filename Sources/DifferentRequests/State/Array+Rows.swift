extension Array {

  /// These rows with `written` in place of the one held under the same id.
  ///
  /// Found by id rather than by an index taken before the write, because a reload can replace the
  /// whole collection while the write is suspended and an index from before that suspension
  /// addresses a different row or runs off the end. A row that is gone by then is left gone: the
  /// write landed, and the next page it appears in will say so.
  func replacingRow(_ written: Element, identifiedBy id: KeyPath<Element, String>) -> [Element] {
    var rows = self
    if let index = rows.firstIndex(where: { $0[keyPath: id] == written[keyPath: id] }) {
      rows[index] = written
    }
    return rows
  }
}
