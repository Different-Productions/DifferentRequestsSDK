import SwiftUI

/// A flat comment thread section: list, official badge, and composer.
///
/// Owns its own ``CommentsThreadModel`` and loads on appear. Embed inside a
/// scrolling detail view (see ``RequestDetailView``); this is not itself a
/// `List` or `ScrollView`, so it can sit alongside other detail content.
///
/// ```swift
/// CommentsSection(client: client, requestId: request.id)
/// ```
public struct CommentsSection: View {

  @State private var model: CommentsThreadModel

  /// Creates a comments section for a request.
  /// - Parameters:
  ///   - client: The DifferentRequests client to use.
  ///   - requestId: The request whose comments to show.
  public init(client: DifferentRequestsClient, requestId: String) {
    self._model = State(initialValue: CommentsThreadModel(client: client, requestId: requestId))
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Comments")
        .font(.headline)

      content

      if let error = model.error {
        Text(error.localizedDescription)
          .font(.callout)
          .foregroundStyle(.red)
      }

      CommentComposer(model: model)
    }
    .task {
      await model.load()
    }
  }

  // MARK: - Content

  @ViewBuilder
  private var content: some View {
    if model.isLoading && model.comments.isEmpty {
      ProgressView()
        .frame(maxWidth: .infinity)
    } else if model.comments.isEmpty {
      Text("No comments yet.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    } else {
      VStack(alignment: .leading, spacing: 16) {
        ForEach(model.comments) { comment in
          CommentRow(
            comment: comment,
            isMine: model.isMine(comment),
            onDelete: { await model.delete(commentId: comment.id) }
          )
        }

        if model.hasMore {
          ProgressView()
            .frame(maxWidth: .infinity)
            .task { await model.loadMore() }
        }
      }
    }
  }
}

// MARK: - Comment Row

private struct CommentRow: View {
  let comment: Comment
  let isMine: Bool
  let onDelete: () async -> Void

  @State private var isDeleting = false

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(comment.authorDisplayName)
            .font(.subheadline)
            .fontWeight(.semibold)

          if comment.isOfficial {
            OfficialBadge()
          }

          Spacer()

          Text(DateFormatting.formatted(comment.createdAt))
            .font(.caption)
            .foregroundStyle(.tertiary)
        }

        Text(comment.body)
          .font(.body)
      }
      .accessibilityElement(children: .combine)

      if isMine {
        Button {
          Task {
            isDeleting = true
            await onDelete()
            isDeleting = false
          }
        } label: {
          Image(systemName: "trash")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .disabled(isDeleting)
        .accessibilityLabel("Delete comment")
        .accessibilityHint("Deletes your comment")
      }
    }
    .opacity(isDeleting ? 0.5 : 1)
  }
}

// MARK: - Official Badge

/// A prominent, filled badge marking a comment as an official/team reply.
///
/// Deliberately more visually assertive than ``StatusBadge`` (filled rather
/// than tinted) since an official reply should stand out from the flat list.
struct OfficialBadge: View {
  var body: some View {
    Label("Official", systemImage: "checkmark.seal.fill")
      .font(.caption)
      .fontWeight(.semibold)
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .foregroundStyle(.white)
      .background(Color.accentColor, in: Capsule())
      .accessibilityLabel("Official reply")
  }
}

// MARK: - Preview

#Preview("Comments Section") {
  ScrollView {
    CommentsSection(
      client: DifferentRequestsClient(apiKey: "preview"),
      requestId: "preview-id"
    )
    .padding()
  }
}

#Preview("Official Badge") {
  OfficialBadge()
    .padding()
}
