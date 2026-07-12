import SwiftUI

/// A compact compose field for posting a new comment.
///
/// Reads and writes ``CommentsThreadModel/draftBody`` directly, so its text
/// survives view recreation and is restored automatically if a post fails.
///
/// ```swift
/// CommentComposer(model: thread)
/// ```
public struct CommentComposer: View {

  @Bindable private var model: CommentsThreadModel

  /// Creates a comment composer bound to a comments thread model.
  /// - Parameter model: The thread model to post through.
  public init(model: CommentsThreadModel) {
    self.model = model
  }

  public var body: some View {
    HStack(alignment: .bottom, spacing: 8) {
      TextField("Add a comment...", text: $model.draftBody, axis: .vertical)
        .textFieldStyle(.roundedBorder)
        .lineLimit(1...5)
        .accessibilityLabel("Comment")
        .accessibilityHint("Enter a comment to post on this request")

      Button {
        Task { await model.post() }
      } label: {
        if model.isPosting {
          ProgressView()
            .frame(width: 32, height: 32)
        } else {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title2)
            .frame(width: 32, height: 32)
        }
      }
      .buttonStyle(.plain)
      .disabled(!model.isDraftValid || model.isPosting)
      .accessibilityLabel("Post comment")
      .accessibilityHint(model.isDraftValid ? "" : "Enter a comment first")
    }
  }
}

// MARK: - Preview

#Preview("Comment Composer") {
  CommentComposer(
    model: CommentsThreadModel(
      client: DifferentRequestsClient(apiKey: "preview"),
      requestId: "preview-id"
    )
  )
  .padding()
}
