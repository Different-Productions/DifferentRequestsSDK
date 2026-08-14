import DifferentRequestsProtos
import SwiftUI

/// What shipped, newest first.
///
/// ```swift
/// NavigationStack {
///   ChangelogView(hub: requests)
/// }
/// ```
///
/// An entry is a release note rather than a shipped request: a release is usually several
/// requests plus work nobody asked for, and it carries prose the requests do not have.
public struct ChangelogView: View {

  private static let entrySpacing: CGFloat = 6
  private static let headerSpacing: CGFloat = 8

  /// The hub's changelog state, which outlives this screen and keeps the pages it has read.
  private let store: ChangelogStore

  /// - Parameter hub: What the host app built once and holds.
  public init(hub: DifferentRequestsHub) {
    self.store = hub.changelog
  }

  public var body: some View {
    content
      .navigationTitle("What's New")
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
    case .failed:
      LoadFailure {
        await store.load()
      }
    case .excluded:
      AbsentSurface(surface: .changelog)
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
    case .failed:
      LoadFailure {
        await store.load()
      }
    case .empty:
      ContentUnavailableView {
        Label("Nothing published yet", systemImage: "sparkles")
      } description: {
        Text("Release notes will appear here.")
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
        Text(entry.title)
          .font(.headline)

        if entry.version.isEmpty == false {
          Text(entry.version)
            .font(.caption)
            .monospaced()
            .foregroundStyle(.secondary)
        }

        Spacer()
      }

      if entry.hasPublishedAt {
        Text(entry.publishedAt.date.formatted(.relative(presentation: .named)))
          .font(.caption)
          .foregroundStyle(.tertiary)
      }

      if entry.body.isEmpty == false {
        Text(entry.body)
          .font(.subheadline)
      }
    }
    .padding(.vertical, Self.entrySpacing)
  }
}
