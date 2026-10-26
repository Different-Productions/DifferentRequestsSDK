import SwiftUI

/// Everything the SDK draws, as tabs: Requests and Inbox always, Roadmap and What's New where the
/// app's plan includes them, with the system search button beside them.
///
/// Presented over the host app, reading from the hub the host built once:
///
/// ```swift
/// .sheet(isPresented: $isShowingRequests) {
///   DifferentRequestsView(hub: requests)
/// }
/// ```
///
/// Each tab brings its own `NavigationStack`, so do not put this inside one.
///
/// A tab exists only once the app's configuration says its plan includes the screen. An unread
/// configuration includes neither, so no tab appears and then goes away.
///
/// Search is the Requests list narrowed by what is typed. The text is cleared on leaving search, so
/// the Requests tab is always the whole board.
public struct DifferentRequestsView: View {

  /// What every tab reads from.
  let hub: DifferentRequestsHub

  /// The tab being shown.
  @State private var tab = ScreenTab.requests

  /// - Parameter hub: What the host app built once and holds. Every screen's state lives on it.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
  }

  public var body: some View {
    @Bindable var board = hub.board

    TabView(selection: $tab) {
      Tab(value: ScreenTab.requests) {
        NavigationStack {
          RequestsScreen(hub: hub)
        }
      } label: {
        Label {
          Text("Requests", bundle: .module, comment: "Title of the request board")
        } icon: {
          Image(systemName: "bubble.left.fill")
        }
      }

      if hub.appConfig.config.roadmapEnabled {
        Tab(value: ScreenTab.roadmap) {
          NavigationStack {
            RoadmapView(hub: hub)
          }
        } label: {
          Label {
            Text("Roadmap", bundle: .module, comment: "Title of the roadmap screen")
          } icon: {
            Image(systemName: "map.fill")
          }
        }
      }

      if hub.appConfig.config.changelogEnabled {
        Tab(value: ScreenTab.changelog) {
          NavigationStack {
            ChangelogView(hub: hub)
          }
        } label: {
          Label {
            Text("What's New", bundle: .module, comment: "Tab and title of the app's release notes screen")
          } icon: {
            Image(systemName: "sparkles")
          }
        }
      }

      Tab(value: ScreenTab.inbox) {
        NavigationStack {
          InboxView(hub: hub)
        }
      } label: {
        Label {
          Text("Inbox", bundle: .module, comment: "Tab and title of the screen listing updates on requests")
        } icon: {
          Image(systemName: "tray.fill")
        }
      }
      .badge(hub.inbox.unreadCount)

      Tab(value: ScreenTab.search, role: .search) {
        NavigationStack {
          RequestsScreen(hub: hub)
        }
        .onDisappear {
          hub.board.query = ""
        }
      }
    }
    .searchable(
      text: $board.query,
      prompt: Text("Search requests", bundle: .module, comment: "Placeholder in the request board's search field")
    )
    .worn(by: hub)
    .sheetMinimumSize()
    .task {
      await hub.appConfig.load()
      await hub.whoIsHere.read()
      // The Inbox tab's badge is the server's own unread count, which the inbox reads with its
      // first page.
      if hub.whoIsHere.somebodyIsHere {
        await hub.inbox.load()
      }
    }
  }
}
