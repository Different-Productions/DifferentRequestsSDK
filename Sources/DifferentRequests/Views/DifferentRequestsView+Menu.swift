import SwiftUI

extension DifferentRequestsView {

  /// Everything this screen can do that is not on the board itself: asking for something, and the
  /// other surfaces this app includes.
  ///
  /// One menu rather than a menu beside a button. The surfaces are built from the configuration,
  /// so one the app does not have is absent rather than present and refused when tapped.
  var everythingElse: some View {
    Menu {
      // Asking and the inbox belong to a person, so neither is offered with nobody signed in.
      if hub.whoIsHere.somebodyIsHere {
        Button {
          hub.beginSubmission()
          isComposing = true
        } label: {
          Label {
            Text("New request", bundle: .module, comment: "Button that opens the form for a new feature request")
          } icon: {
            Image(systemName: "plus.bubble")
          }
        }

        Divider()

        NavigationLink { InboxView(hub: hub) } label: {
          Label {
            Text("Inbox", bundle: .module, comment: "Menu item and title of the screen listing updates on requests")
          } icon: {
            Image(systemName: "bell")
          }
        }
      }
      if hub.appConfig.config.roadmapEnabled {
        NavigationLink { RoadmapView(hub: hub, isShowingRequests: nil) } label: {
          Label {
            Text("Roadmap", bundle: .module, comment: "Title of the roadmap screen")
          } icon: {
            Image(systemName: "map")
          }
        }
      }
      if hub.appConfig.config.changelogEnabled {
        NavigationLink { ChangelogView(hub: hub, isShowingRequests: nil) } label: {
          Label {
            Text("What's New", bundle: .module, comment: "Menu item and title of the app's release notes screen")
          } icon: {
            Image(systemName: "sparkles")
          }
        }
      }
    } label: {
      Label {
        Text("More", bundle: .module, comment: "Menu holding the request board's other screens")
      } icon: {
        Image(systemName: "ellipsis")
      }
    }
  }
}
