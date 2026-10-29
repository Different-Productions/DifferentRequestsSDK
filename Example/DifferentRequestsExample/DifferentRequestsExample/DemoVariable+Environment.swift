extension DemoVariable {

  /// What `environment` sets this variable to, or nothing where it is unset or empty.
  func setting(in environment: [String: String]) -> String? {
    if let name = token, let stated = environment[name], stated.isEmpty == false {
      return stated
    }
    return nil
  }
}
