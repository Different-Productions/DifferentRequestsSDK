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
/// host opens its requests list. Built with `init(hub:)`, it offers nothing. Shown as the first
/// screen of a sheet, it draws the system close button.
///
/// An update is a release note, not a shipped request: a release is usually several requests plus
/// work nobody asked for, and it carries prose the requests do not have.
public struct ChangelogView: View {

  /// What the screen reads from, the look it is drawn in included.
  private let hub: DifferentRequestsHub

  /// Set to `true` by **See requests** on an empty What's New, or nil when the host gave no way
  /// there.
  private let isShowingRequests: Binding<Bool>?

  /// - Parameters:
  ///   - hub: What the host app built once and holds.
  ///   - isShowingRequests: What opens the host's requests list, or nil for no **See requests**.
  public init(hub: DifferentRequestsHub, isShowingRequests: Binding<Bool>?) {
    self.hub = hub
    self.isShowingRequests = isShowingRequests
  }

  /// What's New with no **See requests**, for where the requests list is already one tap away.
  ///
  /// - Parameter hub: What the host app built once and holds.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
    self.isShowingRequests = nil
  }

  public var body: some View {
    ChangelogContent(hub: hub, isShowingRequests: isShowingRequests)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .groupedBackground()
      .navigationTitle(Text("What's New", bundle: .module, comment: "Tab and title of the app's release notes screen"))
      .worn(by: hub)
      .sheetCloseButton()
      .sheetMinimumSize()
      .firstRead(hub.changelog.read) {
        await hub.changelog.load()
      }
  }
}
