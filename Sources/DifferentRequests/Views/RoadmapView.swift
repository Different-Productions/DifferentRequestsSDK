import SwiftUI

/// The roadmap: what is planned, what is being built, and what shipped.
///
/// ```swift
/// NavigationStack {
///   RoadmapView(hub: requests, requestsPresentation: $requestsPresentation)
/// }
/// ```
///
/// Handed a binding, an empty roadmap offers **See requests**, which sets its `showing` so the host
/// opens its requests list. Built with `init(hub:)`, it offers nothing. Shown as the first screen of
/// a sheet, it draws the system close button.
///
/// A section per status, stacked, so all of them are readable at phone width. Each is a bounded
/// page the server chose, so its heading states the whole count, and the Requests list is where a
/// long one is read.
public struct RoadmapView: View {

  /// What the screen reads from, and what a push from a row is built against.
  private let hub: DifferentRequestsHub

  /// Set showing by **See requests** on an empty roadmap, or nil when the host gave no way there.
  private let requestsPresentation: Binding<RequestsPresentation>?

  /// - Parameters:
  ///   - hub: What the host app built once and holds.
  ///   - requestsPresentation: What opens the host's requests list, or nil for no **See requests**.
  public init(hub: DifferentRequestsHub, requestsPresentation: Binding<RequestsPresentation>?) {
    self.hub = hub
    self.requestsPresentation = requestsPresentation
  }

  /// The roadmap with no **See requests**, for where the requests list is already one tap away.
  ///
  /// - Parameter hub: What the host app built once and holds.
  public init(hub: DifferentRequestsHub) {
    self.hub = hub
    self.requestsPresentation = nil
  }

  public var body: some View {
    RoadmapContent(hub: hub, requestsPresentation: requestsPresentation)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .groupedBackground()
      .navigationTitle(Text("Roadmap", bundle: .module, comment: "Title of the roadmap screen"))
      .worn(by: hub)
      .sheetCloseButton()
      .sheetMinimumSize()
      .task {
        // Every appearance: a vote cast elsewhere changes the rows' votes, and the roadmap has no
        // pages to lose. What is held stays on screen while it reads.
        await hub.roadmap.load()
      }
  }
}
