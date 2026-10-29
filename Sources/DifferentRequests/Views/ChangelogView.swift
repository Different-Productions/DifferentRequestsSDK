import SwiftUI

/// What shipped, newest first.
///
/// ```swift
/// NavigationStack {
///   ChangelogView(hub: requests, requestsPresentation: $requestsPresentation)
/// }
/// ```
///
/// Handed a binding, an empty What's New offers **See requests**, which sets its `showing` so the
/// host opens its requests list. Built with `init(hub:)`, it offers nothing. Shown as the first
/// screen of a sheet, it draws the system close button.
///
/// An update is a release note, not a shipped request: a release is usually several requests plus
/// work nobody asked for, and it carries prose the requests do not have.
public struct ChangelogView: View {

  /// What the screen reads from, the look it is drawn in included.
  private let hub: DifferentRequestsHub

  /// Set showing by **See requests** on an empty What's New, or nil when the host gave no way
  /// there.
  private let requestsPresentation: Binding<RequestsPresentation>?

  /// - Parameters:
  ///   - hub: What the host app built once and holds.
  ///   - requestsPresentation: What opens the host's requests list, or nil for no **See requests**.
  public init(hub: DifferentRequestsHub, requestsPresentation: Binding<RequestsPresentation>?) {
    self.hub = hub
    self.requestsPresentation = requestsPresentation
  }

  /// What's New with no **See requests**, for where the requests list is already one tap away.
  ///
  /// - Parameter hub: What the host app built once and holds.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
    self.requestsPresentation = nil
  }

  public var body: some View {
    ChangelogContent(hub: hub, requestsPresentation: requestsPresentation)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .groupedBackground()
      .navigationTitle(Text("What's New", bundle: .module, comment: "Tab and title of the app's release notes screen"))
      .worn(by: hub)
      .sheetCloseButton()
      .sheetMinimumSize()
      .task {
        // A guard, never a task id: the store outlives this screen, and an id flips mid-read.
        if hub.changelog.hasRead() == false {
          await hub.changelog.load()
        }
      }
  }
}
