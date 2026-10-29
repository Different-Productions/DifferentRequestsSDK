extension CharactersLeftContent {

  /// The room left under `limit` once `typed` is in the field. Negative once it is over.
  init(limit: Int, typed: String) {
    self.init()
    left = Int32(limit - typed.count)
  }
}
