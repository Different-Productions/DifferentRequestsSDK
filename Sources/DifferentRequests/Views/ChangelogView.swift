import DifferentRequestsProtos
import SwiftUI

/// What shipped, newest first.
///
/// ```swift
/// NavigationStack {
///   ChangelogView(hub: requests, isShowingRequests: $isShowingRequests)
/// }
/// ```
///
/// Handed a binding, an empty What's New offers **See requests**, which sets it to `true` so the
/// host opens its requests list. Handed `nil`, it offers nothing: pushed from the board, the back
/// button already goes there. Shown as the first screen of a sheet, it draws its own Done.
///
/// An entry is a release note rather than a shipped request: a release is usually several
/// requests plus work nobody asked for, and it carries prose the requests do not have.
public struct ChangelogView: View {

  private static let entrySpacing: CGFloat = 6
  private static let headerSpacing: CGFloat = 8

  /// What the screen reads from, the look it is drawn in included.
  private let hub: DifferentRequestsHub

  /// The hub's changelog state, which outlives this screen and keeps the pages it has read.
  private let store: ChangelogStore

  /// Set to `true` by **See requests** on an empty What's New, or nil when the host gave no way
  /// there.
  private let isShowingRequests: Binding<Bool>?

  /// - Parameters:
  ///   - hub: What the host app built once and holds.
  ///   - isShowingRequests: What opens the host's requests list, or nil for no **See requests**.
  public init(hub: DifferentRequestsHub, isShowingRequests: Binding<Bool>?) {
    self.hub = hub
    self.store = hub.changelog
    self.isShowingRequests = isShowingRequests
  }

  public var body: some View {
    content
      .navigationTitle(Text("What's New", bundle: .module, comment: "Menu item and title of the app's release notes screen"))
      .worn(by: hub.appearanceDrawn)
      .sheetDoneButton()
      .sheetMinimumSize()
      .firstRead(store.read) {
        await store.load()
      }
  }

  // MARK: - Content

  /// Whether this app publishes release notes is asked before anything is drawn, and answered on
  /// the screen rather than by a read that would come back refused. An app that does not publish
  /// them is not a failure and not an empty changelog: it is a screen that says what is there
  /// instead.
  @ViewBuilder
  private var content: some View {
    switch store.plan {
    case .unread, .reading:
      ProgressView()
    case .failed(let error):
      LoadFailure(error: error) {
        await store.load()
      }
    case .excluded:
      AbsentSurface(surface: .changelog, isShowingRequests: isShowingRequests)
    case .included:
      entries
    }
  }

  /// Four outcomes, from one state. The list stays up through a refresh even while its rows are
  /// being replaced: a pull-to-refresh runs on the list's own task, and a list that disappears
  /// takes that task with it.
  @ViewBuilder
  private var entries: some View {
    switch store.read {
    case .unread, .reading:
      ProgressView()
    case .failed(let error):
      LoadFailure(error: error) {
        await store.load()
      }
    case .empty:
      ContentUnavailableView {
        Label {
          Text("Nothing new yet", bundle: .module, comment: "Heading on an empty release notes screen")
        } icon: {
          Image(systemName: "sparkles")
        }
      } description: {
        Text(
          "When the app gets something new, you'll read about it here.",
          bundle: .module,
          comment: "Message on an empty release notes screen"
        )
      } actions: {
        if let isShowingRequests {
          SeeRequestsButton(isShowingRequests: isShowingRequests)
        }
      }
    case .loaded(let held), .refreshing(let held):
      list(held)
    }
  }

  private func list(_ entries: [DRChangelogEntry]) -> some View {
    List {
      ForEach(entries, id: \.id) { entry in
        row(entry)
      }

      if store.page.isDone == false {
        NextPageRow(state: store.page) {
          await store.loadMore()
        }
      }
    }
    .refreshable {
      await store.load()
    }
  }

  private func row(_ entry: DRChangelogEntry) -> some View {
    VStack(alignment: .leading, spacing: Self.entrySpacing) {
      HStack(spacing: Self.headerSpacing) {
        if entry.title.isEmpty {
          Text(entry.version)
            .font(.headline)
        } else {
          Text(entry.title)
            .font(.headline)

          if entry.version.isEmpty == false {
            Text(entry.version)
              .font(.caption)
              .monospaced()
              .foregroundStyle(.secondary)
          }
        }

        Spacer()
      }

      if entry.hasPublishedAt {
        Text(entry.publishedAt.date.ago)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }

      if entry.body.isEmpty == false {
        Text(entry.body)
          .font(.subheadline)
      }

      if entry.answers.isEmpty == false {
        Text("What this answers", bundle: .module, comment: "Heading over the requests a What's New entry answers")
          .font(.caption.weight(.semibold))
          .textCase(.uppercase)
          .foregroundStyle(.secondary)
          .padding(.top, Self.entrySpacing)

        ForEach(entry.answers, id: \.requestID) { answer in
          NavigationLink {
            RequestDetailView(hub: hub, requestID: answer.requestID)
          } label: {
            ChangelogAnswerRow(answer: answer)
          }
        }
      }
    }
    .padding(.vertical, Self.entrySpacing)
  }
}
