import DifferentRequestsProtos
import SwiftUI

/// What shipped, newest first.
///
/// ```swift
/// NavigationStack {
///   ChangelogView(client: client)
/// }
/// ```
///
/// An entry is a release note rather than a shipped request: a release is usually several
/// requests plus work nobody asked for, and it carries prose the requests do not have.
public struct ChangelogView: View {

  private static let entrySpacing: CGFloat = 6
  private static let headerSpacing: CGFloat = 8

  private let store: ChangelogStore

  /// - Parameter client: The client the changelog reads through.
  public init(client: DifferentRequestsClient) {
    self.store = ChangelogStore(client: client)
  }

  public var body: some View {
    content
      .navigationTitle("What's New")
      .firstRead(hasLoaded: store.hasLoaded) {
        await store.load()
      }
  }

  // MARK: - Content

  /// The list stays up while a read is in flight even with nothing in it: a pull-to-refresh runs on
  /// the list's own task, and a page cleared at the start of a read would take the list — and the
  /// read with it.
  @ViewBuilder
  private var content: some View {
    if store.hasLoaded == false {
      ProgressView()
    } else if store.entries.isEmpty == false || store.isLoading {
      list
    } else if store.loadError != nil {
      LoadFailure {
        await store.load()
      }
    } else {
      ContentUnavailableView {
        Label("Nothing published yet", systemImage: "sparkles")
      } description: {
        Text("Release notes will appear here.")
      }
    }
  }

  private var list: some View {
    List {
      ForEach(store.entries, id: \.id) { entry in
        row(entry)
      }

      if store.hasMore {
        ProgressView()
          .frame(maxWidth: .infinity)
          .task {
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
