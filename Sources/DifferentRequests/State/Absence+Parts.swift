extension Absence {

  /// The words and symbol a screen draws in place of a surface.
  init(title: String, message: String, symbol: String) {
    self.init()
    self.title = title
    self.message = message
    self.symbol = symbol
  }
}
