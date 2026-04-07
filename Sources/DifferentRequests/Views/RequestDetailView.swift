import SwiftUI

/// A detail view for a single feature request.
///
/// Shows the full title, body, author, timestamps, status, and voting controls.
///
/// ```swift
/// RequestDetailView(client: client, requestId: "abc-123")
/// ```
public struct RequestDetailView: View {

  @State private var model: RequestDetailModel
  private let requestId: String

  /// Creates a request detail view.
  /// - Parameters:
  ///   - client: The DifferentRequests client to use.
  ///   - requestId: The ID of the request to display.
  public init(client: DifferentRequestsClient, requestId: String) {
    self._model = State(initialValue: RequestDetailModel(client: client))
    self.requestId = requestId
  }

  public var body: some View {
    Group {
      if model.isLoading {
        ProgressView("Loading...")
      } else if let error = model.error {
        ContentUnavailableView {
          Label("Failed to load", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.errorDescription ?? "Unknown error")
        } actions: {
          Button("Retry") { Task { await model.load(id: requestId) } }
        }
      } else if let request = model.request {
        requestContent(request)
      }
    }
    .navigationTitle("Request")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    .task {
      await model.load(id: requestId)
    }
  }

  // MARK: - Content

  @ViewBuilder
  private func requestContent(_ request: Request) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {

        // Title + Status
        HStack(alignment: .top) {
          Text(request.title)
            .font(.title2)
            .fontWeight(.bold)
          Spacer()
          StatusBadge(status: request.status)
        }

        // Merged banner
        if let mergedId = request.mergedIntoId {
          Label("Merged into \(mergedId)", systemImage: "arrow.triangle.merge")
            .font(.callout)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }

        // Decline reason
        if request.status == .declined, let reason = request.declineReasonLabel {
          Label("Declined: \(reason)", systemImage: "xmark.circle")
            .font(.callout)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }

        // Vote
        HStack {
          VoteControl(score: request.score) { value in
            await model.vote(value: value)
          }
          Text(request.score == 1 ? "1 vote" : "\(request.score) votes")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        // Body
        Text(request.body)
          .font(.body)

        Divider()

        // Metadata
        VStack(alignment: .leading, spacing: 8) {
          metadataRow("Author", value: request.authorDisplayName)

          if let externalId = request.authorExternalUserId {
            metadataRow("External ID", value: externalId)
          }

          metadataRow("Created", value: DateFormatting.formatted(request.createdAt))
          metadataRow("Updated", value: DateFormatting.formatted(request.updatedAt))
          metadataRow("ID", value: request.id)
        }
      }
      .padding()
    }
  }

  private func metadataRow(_ label: String, value: String) -> some View {
    HStack {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 80, alignment: .leading)
      Text(value)
        .font(.caption)
        .monospaced()
    }
  }
}

// MARK: - Preview

#Preview("Request Detail") {
  NavigationStack {
    RequestDetailView(
      client: DifferentRequestsClient(apiKey: "preview"),
      requestId: "preview-id"
    )
  }
}
