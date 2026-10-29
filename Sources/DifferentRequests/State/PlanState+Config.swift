import DifferentRequestsProtos
import Foundation

extension PlanState {

  /// What an answer to `getConfig` says about one surface.
  ///
  /// A response carrying no `AppConfig` is a failure: every flag on an absent message reads as
  /// `false`, and reading that as an answer would hide every paid surface behind a server that said
  /// nothing.
  init(surface: DRPlanSurface, response: DRGetConfigResponse) {
    self.init()
    if response.hasConfig == false {
      state = .failed(ReadTrouble(error: DifferentRequestsError(incompleteResponse: .getConfig)))
    } else if response.config.includes(surface) {
      state = .included(SurfaceIncluded())
    } else {
      state = .excluded(SurfaceExcluded())
    }
  }

  /// Whether the configuration still has to be asked for: before anything was asked, and again
  /// after a read that failed, so one outage does not hide a surface for the whole launch.
  func needsReading() -> Bool {
    switch state {
    case .none, .failed:
      return true
    case .reading, .excluded, .included:
      return false
    }
  }

  /// Whether this app has the surface. False while the answer is unknown, so a read is never
  /// started on a guess.
  func isIncluded() -> Bool {
    switch state {
    case .included:
      return true
    case .none, .reading, .failed, .excluded:
      return false
    }
  }
}
