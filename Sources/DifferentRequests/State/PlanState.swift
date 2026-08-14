import DifferentRequestsProtos
import Foundation

/// Whether a surface is part of what an app includes, and how far the asking got.
///
/// One value, for the reason a read is one value: a surface that has not asked yet, one that
/// asked and could not get an answer, and one that asked and was told no are three different
/// screens, and a `Bool` is two of them at best. The one that goes missing is always the middle
/// one — a config read that failed, defaulted to `false`, hides a surface the tenant is paying
/// for and says nothing about why.
///
/// Held beside ``ReadState`` rather than folded into it. They are two questions asked in order:
/// whether there is anything here, and then what it says. Only the second has content to hold,
/// and only the first is answered by a call every surface shares.
enum PlanState {

  /// Nothing has been asked.
  case unread

  /// The app's configuration is being read.
  case reading

  /// The configuration did not answer, so whether this surface exists is not known.
  ///
  /// The error is here for whoever is debugging. It is not what a reader is told: the contract
  /// states an `ApiError`'s message is written for a developer reading a log and may name
  /// internals, so the copy on screen is written by the view instead.
  case failed(any Error)

  /// The configuration answered and this app does not have this surface.
  case excluded

  /// The configuration answered and this app has it.
  case included
}

extension PlanState {

  /// What an answer to `getConfig` says about one surface.
  ///
  /// A response carrying no `AppConfig` at all is a failure rather than an empty one. Every flag
  /// on an absent message reads as `false`, so treating it as an answer would take a server that
  /// said nothing and hide every paid surface behind it — which is the same defect as rendering a
  /// surface nobody asked about, arrived at from the other side.
  init(surface: PlanSurface, response: DRGetConfigResponse) {
    if response.hasConfig == false {
      self = .failed(DifferentRequestsError.incompleteResponse(.getConfig))
    } else if surface.isIncluded(in: response.config) {
      self = .included
    } else {
      self = .excluded
    }
  }

  /// Whether the configuration still has to be asked for.
  ///
  /// True while nothing has been asked, and true again after a read that failed: the reason a
  /// config read fails is usually a connection that has since come back, and a surface that
  /// remembers one outage forever is a surface nobody can reach again this launch. False once an
  /// answer has arrived, which is what stops a screen from re-asking on every appearance.
  var needsReading: Bool {
    switch self {
    case .unread, .failed:
      return true
    case .reading, .excluded, .included:
      return false
    }
  }

  /// Whether this app has the surface. What a store checks before reading one at all.
  ///
  /// False while the answer is still unknown, so a read is never started on a guess: a surface
  /// the app turns out not to have would have spent a round trip to be told so.
  var isIncluded: Bool {
    switch self {
    case .unread, .reading, .failed, .excluded:
      return false
    case .included:
      return true
    }
  }

  /// The failure the last configuration read ended in, for a host app that wants to log it or
  /// branch on its `DifferentRequestsError` case. Nil in every other state.
  var failure: (any Error)? {
    switch self {
    case .unread, .reading, .excluded, .included:
      return nil
    case .failed(let error):
      return error
    }
  }
}
