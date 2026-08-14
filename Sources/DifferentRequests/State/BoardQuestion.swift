import DifferentRequestsProtos

/// Everything one page of the board is an answer to: which statuses it covers, how it is ranked,
/// and what was searched for.
///
/// One value rather than three properties compared one at a time. A cursor addresses the results of
/// the question it was handed back for and nothing else, so any of the three moving invalidates
/// every page held under the old one — and a staleness check written per property is one that a
/// fourth property gets added past. Written as a value, the check is `!=` and cannot be
/// half-updated.
///
/// Equatable by every field it has, including the order of ``statuses``. That order is not
/// incidental: the client joins the statuses into one comma-separated query value, so two orders of
/// the same set are two different URLs, and the store keeps them in the order the contract declares
/// them so the same set is always spelled the same way.
struct BoardQuestion: Equatable {

  /// Which statuses the board covers. Empty is everything still on it.
  let statuses: [DRRequestStatus]

  /// Whether the board is ranked by demand or by recency.
  let sort: DRRequestSort

  /// Free text over title and body. Empty is the whole board.
  let query: String
}
