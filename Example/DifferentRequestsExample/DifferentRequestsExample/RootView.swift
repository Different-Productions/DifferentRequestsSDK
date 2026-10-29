import DifferentRequests
import SwiftUI

/// The app's root: a host app with somewhere to open feedback from.
///
/// This is what an integration looks like. The SDK is not the app — it is a set of screens
/// presented over one, reached from rows a host puts wherever they make sense.
///
/// Nothing here decides anything. Which rows exist, what the badge says, and which screen is up are
/// all read off ``Session``; this draws them and navigates.
struct RootView: View {
  private let session: Session

  init(session: Session) {
    self.session = session
  }

  var body: some View {
    phaseContent()
      .task {
        await session.start()
      }
  }

  // MARK: - Phases

  @ViewBuilder
  private func phaseContent() -> some View {
    switch session.state.phase.phase {
    case .unconfigured:
      ContentUnavailableView {
        Label("No API key", systemImage: "key.slash")
      } description: {
        if let variable = DemoVariable.appKey.token {
          Text(
            """
            Set \(variable) in the scheme's \
            Run, Arguments, Environment Variables, then run again.
            """
          )
        }
      }

    case .reading, .none:
      ProgressView("Starting…")

    case .ready, .configUnreadable:
      home()
    }
  }

  // MARK: - The host app

  /// A settings list with one row per surface, which is the whole integration.
  private func home() -> some View {
    NavigationStack {
      List {
        Section {
          ForEach(session.state.screens, id: \.self) { screen in
            row(for: screen)
          }
        } header: {
          Text("Your app")
        } footer: {
          Text("Everything in this list is drawn by the SDK and presented over your app. Nothing about how it looks is written here.")
        }
      }
      .navigationTitle("Example")
    }
    .sheet(isPresented: presenting()) {
      presented(session.state.showing)
    }
  }

  /// One row: what it is, what it gives you, and the badge where a badge belongs.
  ///
  /// `.plain` so the row reads as a settings row rather than four lines of tinted text — a button's
  /// style tints every label inside it, including the explanation, which is not a link.
  private func row(for screen: ExampleScreen) -> some View {
    Button {
      session.show(screen)
    } label: {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        if let symbol = screen.token {
          Image(systemName: symbol)
            .foregroundStyle(.tint)
            .frame(width: 22)
        }
        VStack(alignment: .leading, spacing: 3) {
          Text(LocalizedStringKey(screen.label))
          Text(LocalizedStringKey(screen.pitch))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        if session.badgeCount(for: screen) > 0 {
          Text("\(Int(session.badgeCount(for: screen)))")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(.red))
        }
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  /// The SDK screen for a row, each one presented exactly as its documentation shows. The SDK's
  /// screens draw their own Done on a sheet; Diagnostics is this app's, so it gets the app's.
  @ViewBuilder
  private func presented(_ screen: ExampleScreen) -> some View {
    switch screen {
    case .requests:
      DifferentRequestsView(hub: session.hub)
    case .inbox:
      NavigationStack {
        InboxView(hub: session.hub)
      }
    case .roadmap:
      NavigationStack {
        RoadmapView(hub: session.hub, requestsPresentation: requestsPresentation())
      }
    case .changelog:
      NavigationStack {
        ChangelogView(hub: session.hub, requestsPresentation: requestsPresentation())
      }
    case .diagnostics:
      NavigationStack {
        DiagnosticsView(session: session)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              DoneButton()
            }
          }
      }
    case .unspecified, .UNRECOGNIZED:
      EmptyView()
    }
  }

  /// What an empty Roadmap or What's New sets to open this app's requests list in place of it.
  private func requestsPresentation() -> Binding<RequestsPresentation> {
    Binding {
      var presentation = RequestsPresentation()
      presentation.showing = session.isShowing(.requests)
      return presentation
    } set: { presentation in
      if presentation.showing {
        session.show(.requests)
      }
    }
  }

  /// What the sheet is bound to: up while the session shows a screen.
  ///
  /// Both directions are recorded. A setter that answered only the dismissal would leave SwiftUI
  /// holding one screen and the session holding another.
  private func presenting() -> Binding<Bool> {
    Binding {
      session.isShowingAny()
    } set: { shown in
      if shown == false {
        session.screenDismissed()
      }
    }
  }
}
