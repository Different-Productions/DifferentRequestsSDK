import SwiftUI

/// A form for submitting a new feature request.
///
/// Includes title and body fields, live duplicate search as the user types,
/// and a submit button. Presented as a sheet from ``DifferentRequestsView``.
///
/// ```swift
/// .sheet(isPresented: $showSubmit) {
///   SubmitRequestView(client: client) {
///     await model.refresh()
///   }
/// }
/// ```
public struct SubmitRequestView: View {

  @State private var model: SubmitRequestModel
  @State private var searchTask: Task<Void, Never>?
  @Environment(\.dismiss) private var dismiss

  private let onSubmitted: () async -> Void

  /// Creates a submit request view.
  /// - Parameters:
  ///   - client: The DifferentRequests client to use.
  ///   - onSubmitted: Called after a successful submission (e.g., to refresh the list).
  public init(client: DifferentRequestsClient, onSubmitted: @escaping () async -> Void) {
    self._model = State(initialValue: SubmitRequestModel(client: client))
    self.onSubmitted = onSubmitted
  }

  public var body: some View {
    NavigationStack {
      Form {
        titleSection
        bodySection
        similarSection

        if let error = model.error {
          Section {
            Text(error.errorDescription ?? "Unknown error")
              .foregroundStyle(.red)
              .font(.callout)
          }
        }
      }
      .navigationTitle("Submit request")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Submit") {
            Task { await handleSubmit() }
          }
          .disabled(!model.isValid || model.isSubmitting)
        }
      }
    }
  }

  // MARK: - Sections

  private var titleSection: some View {
    Section {
      TextField("Title", text: $model.title)
        .onChange(of: model.title) { _, newValue in
          searchTask?.cancel()
          let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
          guard trimmed.count >= 3 else {
            return
          }
          searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await model.searchSimilar()
          }
        }
    } header: {
      Text("Title")
    }
  }

  private var bodySection: some View {
    Section {
      TextEditor(text: $model.body)
        .frame(minHeight: 120)
    } header: {
      Text("Description")
    }
  }

  @ViewBuilder
  private var similarSection: some View {
    if !model.similarRequests.isEmpty {
      Section {
        ForEach(model.similarRequests) { request in
          VStack(alignment: .leading, spacing: 4) {
            Text(request.title)
              .font(.subheadline)
              .fontWeight(.medium)
            HStack(spacing: 8) {
              StatusBadge(status: request.status)
              Text("\(request.score) votes")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 2)
        }
      } header: {
        Text("Similar requests")
      } footer: {
        Text("Check if your request already exists before submitting.")
      }
    }

    if model.isSearching {
      Section {
        ProgressView("Searching...")
      }
    }
  }

  // MARK: - Actions

  private func handleSubmit() async {
    let request = await model.submit()
    if request != nil {
      await onSubmitted()
      dismiss()
    }
  }
}

// MARK: - Preview

#Preview("Submit Request") {
  SubmitRequestView(
    client: DifferentRequestsClient(apiKey: "preview"),
    onSubmitted: {}
  )
}
