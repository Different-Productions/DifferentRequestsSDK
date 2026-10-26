import SwiftUI

/// A label drawn as its title alone, as wide as it is offered, so two stacked buttons are one size.
struct WideTitleLabelStyle: LabelStyle {

  func makeBody(configuration: Configuration) -> some View {
    configuration.title
      .frame(maxWidth: .infinity)
  }
}
