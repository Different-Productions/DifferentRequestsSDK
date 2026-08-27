import DifferentRequestsProtos
import Foundation

/// A surface whose existence is the tenant's to decide rather than this package's.
///
/// The roadmap and the changelog are Pro anchors and are absent on Free. Comments are free on
/// every plan and are absent when the tenant has chosen not to moderate a discussion. Three
/// different reasons and one shape: `AppConfig` says which of them an app has, and a screen drawn
/// for one the app does not have is a screen whose only possible answer is a refusal.
///
/// What each case carries is what the person is looking at instead. Nothing here says what the
/// plan is, what the missing surface would cost, or that a plan is involved at all: the contract
/// states `planRequired` is written for the host developer, is the one error whose remedy is a
/// purchase, and is never surfaced to an end user. Someone using a host app did not choose the
/// plan and cannot change it, so being told about it would be being told about somebody else's
/// decision.
enum PlanSurface: CaseIterable {

  /// What is planned, being built, and shipped. `AppConfig.roadmapEnabled`.
  case roadmap

  /// Published release notes. `AppConfig.changelogEnabled`.
  case changelog

  /// Whether a request takes replies. `AppConfig.commentsEnabled`.
  case comments
}

extension PlanSurface {

  /// This surface as the contract names it, which is what `DRAppConfig.includes(_:)` answers for.
  ///
  /// Every case here is drawable and so has a name in the contract. The contract's own enum also
  /// carries `unspecified` and `UNRECOGNIZED`, which name no screen and so are not reachable from
  /// this side.
  var theSurfaceTheContractNames: DRPlanSurface {
    switch self {
    case .roadmap:
      return .roadmap
    case .changelog:
      return .changelog
    case .comments:
      return .comments
    }
  }

  /// The heading on the screen someone gets in place of this surface.
  ///
  /// Written as a fact about the app rather than as a failure, because it is one: nothing went
  /// wrong, and there was never anything here to reach.
  var absentTitle: String {
    switch self {
    case .roadmap:
      return "This app has no roadmap"
    case .changelog:
      return "This app has no release notes"
    case .comments:
      return "Comments are off"
    }
  }

  /// What is there instead, which is the part worth reading.
  ///
  /// Each names somewhere to go that exists on every plan — the board takes requests and every
  /// request takes votes — so nobody is left at a dead end being told what is not there.
  var absentDescription: String {
    switch self {
    case .roadmap:
      return "It doesn't publish one. What people have asked for is on the board."
    case .changelog:
      return "It doesn't publish them. What people have asked for is on the board."
    case .comments:
      return "This app doesn't take them. Voting is how you say you want this."
    }
  }

  /// The symbol beside the heading. The same one the surface itself uses, because it is the same
  /// subject and the picture is not what is missing.
  var absentSymbol: String {
    switch self {
    case .roadmap:
      return "map"
    case .changelog:
      return "sparkles"
    case .comments:
      return "bubble.left"
    }
  }
}
