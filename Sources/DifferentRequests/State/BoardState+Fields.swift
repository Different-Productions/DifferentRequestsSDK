import DifferentRequestsProtos
import SwiftProtobuf

extension BoardState {

  /// The whole board ranked by `sort` and nothing else: every status still on it, unsearched, with
  /// no page read, and a search that settles for 300 ms before it is sent.
  ///
  /// The question asked is the one the board was built for, so `loadMore()` before any `load()`
  /// pages the board as constructed rather than paging nothing.
  init(sort: DRRequestSort) {
    self.init()
    self.sort = sort
    asked.sort = sort
    searchSettleDelay = Google_Protobuf_Duration(seconds: 0, nanos: 300_000_000)
  }
}
