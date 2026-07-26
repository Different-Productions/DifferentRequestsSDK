import SwiftUI

/// A button whose action is asynchronous.
///
/// `Button` takes a synchronous action and every action on these surfaces is a store method that
/// suspends, so something has to bridge the two. This is the only place in the SDK that does, and
/// the bridge is a task rather than a `task(id:)` bound to this button on purpose: several of
/// these actions remove the button that started them — a retry that succeeds replaces the failure
/// notice it sits in, a dot marked read disappears — and a call cancelled by its own answer would
/// undo the very thing it just achieved.
///
/// Disabled while the action runs, which is what stops a second tap from writing twice.
struct AsyncButton<Label: View>: View {

  private let action: () async -> Void
  private let label: Label

  /// `true` from the tap until the action finishes.
  @State private var isRunning: Bool = false

  init(action: @escaping () async -> Void, @ViewBuilder label: () -> Label) {
    self.action = action
    self.label = label()
  }

  var body: some View {
    Button {
      isRunning = true
      Task {
        await action()
        isRunning = false
      }
    } label: {
      label
    }
    .disabled(isRunning)
  }
}
