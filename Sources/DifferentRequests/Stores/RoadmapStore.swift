import DifferentRequestsProtos
import Foundation

/// Backs the roadmap: what is planned, what is being built, and what shipped.
///
/// Wraps `DifferentRequestsClient.roadmap()`, which answers with the whole roadmap in one read.
/// There is no pagination and no cursor here on purpose — a roadmap is a summary, each column is
/// a bounded page the server chose, and a column with four hundred planned items is a question
/// the board answers rather than the roadmap.
///
/// The columns are kept in the order the server sent them. Ordering is the server's to decide so
/// every client's roadmap reads the same way.
///
/// Two states: whether this app has a roadmap at all, and then what is on it. `GetRoadmap` is one
/// of exactly two rpcs the server refuses on plan, so a roadmap read by an app that does not have
/// one is a round trip whose only possible answer is a refusal — and a refusal the person looking
/// at the screen must never be shown, because the contract writes `planRequired` for the host
/// developer and the remedy is a purchase only they can make.
///
/// Nothing is written from this surface, and there is no paging: a column is a bounded page the
/// server chose.
///
/// Main-actor isolated and observable.
@MainActor
@Observable
final class RoadmapStore {

  // MARK: - Inputs

  /// The client every call goes through.
  let client: DifferentRequestsClient

  // MARK: - State

  /// Whether this app has a roadmap, and how far the asking got.
  var plan: PlanState = .unread

  /// The roadmap itself: where its read got to, and the columns it found, in display order.
  var read: ReadState<[DRRoadmapColumn]> = .unread

  // MARK: - Init

  /// - Parameter client: The client the roadmap reads through.
  init(client: DifferentRequestsClient) {
    self.client = client
  }

  // MARK: - Loading

  /// Asks what this app includes, then reads the roadmap if it has one.
  ///
  /// Returns immediately when a read is already running. Also the retry behind both failures the
  /// screen can show: the configuration is asked for again when the last ask did not answer, and
  /// asked for once when it did.
  func load() async {
    if read.isReading { return }

    await readPlan()
    if plan.isIncluded {
      await readColumns()
    }
  }

  /// Asks whether this app has a roadmap.
  ///
  /// The client answers a second ask from the first read, so the cost of every gated surface
  /// asking for itself is one round trip for all of them.
  private func readPlan() async {
    if plan.needsReading == false { return }
    plan = .reading

    do {
      let answer = try await client.config()
      plan = PlanState(surface: .roadmap, response: answer)
    } catch {
      plan = .failed(error)
    }
  }

  /// Reads the columns.
  ///
  /// What is already held stays on screen for the length of the read, and a read that fails
  /// replaces it with the failure: columns left up after a refresh that could not reach the server
  /// are a roadmap presenting itself as current when nobody knows whether it is.
  private func readColumns() async {
    read = read.whileReading

    do {
      let answer = try await client.roadmap()
      read = ReadState(page: answer.columns)
    } catch {
      read = ReadState(readFailure: error)
    }
  }
}
