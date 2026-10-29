import DifferentRequestsProtos
import Foundation

extension DRPlanSurface {

  /// What the person sees in place of this surface, or nil for a surface with no screen of its own.
  ///
  /// A fact about the app rather than a failure, and never a word about the plan: the contract says
  /// `planRequired` is for the host developer, and someone using a host app did not choose its plan.
  /// The symbol is the one the surface itself uses, because the picture is not what is missing.
  func absence() -> Absence? {
    switch self {
    case .roadmap:
      return Absence(
        title: String(localized: "This app has no roadmap", bundle: .module, comment: "Heading when the app doesn't publish a roadmap"),
        message: String(
          localized: "This app doesn't share its plans.",
          bundle: .module,
          comment: "Message when the app doesn't publish a roadmap"
        ),
        symbol: "map"
      )
    case .changelog:
      return Absence(
        title: String(
          localized: "This app doesn't post updates",
          bundle: .module,
          comment: "Heading when the app doesn't publish release notes"
        ),
        message: String(
          localized: "If that changes, its updates will show up here.",
          bundle: .module,
          comment: "Message when the app doesn't publish release notes"
        ),
        symbol: "sparkles"
      )
    case .comments:
      return Absence(
        title: String(localized: "Comments are off", bundle: .module, comment: "Heading when the app doesn't take comments on requests"),
        message: String(
          localized: "This app doesn't have comments. Vote to show you want this.",
          bundle: .module,
          comment: "Message when the app doesn't take comments on requests"
        ),
        symbol: "bubble.left"
      )
    case .push, .developerReplies, .folding, .appearance, .planning, .badgeRemoval, .unspecified, .UNRECOGNIZED:
      return nil
    }
  }
}
