import DifferentRequests

extension ExampleScreen {

  /// Whether this app carries this screen at this point in launch.
  ///
  /// The two paid surfaces are answered by the config the server sent, so what the rows offer and
  /// what the rpcs behind them allow cannot disagree. An unread config offers only what every plan
  /// carries.
  func isCarried(in phase: LaunchPhase) -> Bool {
    switch phase.phase {
    case .ready(let config):
      return isCarried(by: config)
    case .configUnreadable:
      return isCarriedByEveryPlan()
    case .unconfigured, .reading, .none:
      return false
    }
  }

  /// Whether `config` includes this screen.
  func isCarried(by config: DRAppConfig) -> Bool {
    switch self {
    case .requests, .inbox, .diagnostics:
      return true
    case .roadmap:
      return config.roadmapEnabled
    case .changelog:
      return config.changelogEnabled
    case .unspecified, .UNRECOGNIZED:
      return false
    }
  }

  /// Whether every plan includes this screen.
  func isCarriedByEveryPlan() -> Bool {
    switch self {
    case .requests, .inbox, .diagnostics:
      return true
    case .roadmap, .changelog, .unspecified, .UNRECOGNIZED:
      return false
    }
  }
}
