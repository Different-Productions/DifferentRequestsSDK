import SwiftUI

#if os(iOS)
  /// The iPhone and iPad tab bar: Requests, Roadmap and What's New where the plan includes them,
  /// Inbox with its unread count, and the system search button.
  struct RequestsTabView: View {

    /// What every tab reads from.
    let hub: DifferentRequestsHub

    /// The tab being shown.
    @State private var tab = ScreenTab.requests

    var body: some View {
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
        .badge(Int(hub.unreadCount()))

        Tab(value: ScreenTab.search, role: .search) {
          NavigationStack {
            RequestsScreen(hub: hub)
          }
          .onDisappear {
            hub.board.board.query = ""
          }
        }
      }
      .searchable(
        text: $board.board.query,
        prompt: Text("Search requests", bundle: .module, comment: "Placeholder in the request board's search field")
      )
    }
  }
#endif
