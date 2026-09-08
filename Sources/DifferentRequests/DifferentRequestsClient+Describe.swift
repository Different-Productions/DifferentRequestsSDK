import DifferentRequestsProtos
import Foundation

extension DifferentRequestsClient {

  /// Everything this client knows about its own setup, as something to read or paste into a support
  /// email.
  ///
  /// A developer looking at an empty board cannot tell these apart: not shipped yet, wrong key, the
  /// old base URL, a surface their plan does not include, or our fault. This answers all five in one
  /// place, and it answers them **from what the server said** rather than from what the client
  /// hoped — the plan lines come off the `AppConfig` that came back, and the last line is the real
  /// status code.
  ///
  /// Reads only state already held. It makes no call, so it is safe to print from anywhere, and an
  /// app that has never reached us says exactly that:
  ///
  /// ```
  /// last call    none yet — this app has never reached the server
  /// ```
  ///
  /// which is the single most useful line on the list.
  public func describeIntegration() -> String {
    var lines = [
      "DifferentRequests \(SDKClient.version) (\(SDKClient.header))",
      "  base URL     \(baseURL.absoluteString)",
      "  app key      \(elidedKey)"
    ]

    if let app = configuration?.config.app {
      lines.append("  app          \(app.name)  (\(app.id))")
    } else {
      lines.append("  app          not fetched yet — call config() to resolve the key")
    }

    if let config = configuration?.config {
      lines.append("  plan         \(planLine(config))")
    }

    lines.append("  last call    \(lastCallLine)")
    return lines.joined(separator: "\n")
  }

  /// The tail of the key and nothing else. Enough to match against the one in a binary, useless to
  /// anybody who reads it over a shoulder or in a pasted support email.
  private var elidedKey: String {
    let tail = appKey.suffix(4)
    return tail.isEmpty ? "(empty)" : "…\(tail)"
  }

  private func planLine(_ config: DRAppConfig) -> String {
    let surfaces = [
      "roadmap \(config.roadmapEnabled ? "yes" : "no")",
      "changelog \(config.changelogEnabled ? "yes" : "no")",
      "comments \(config.commentsEnabled ? "yes" : "no")",
      "badge \(config.showBadge ? "shown" : "hidden")"
    ]
    return "\(config.app.plan)  —  \(surfaces.joined(separator: ", "))"
  }

  private var lastCallLine: String {
    switch lastCall {
    case .none:
      return "none yet — this app has never reached the server"
    case .made(let rpc, let outcome, let at):
      return "\(rpc) → \(outcome)  (\(at.formatted(.iso8601)))"
    }
  }
}
