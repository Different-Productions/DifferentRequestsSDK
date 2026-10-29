import SwiftUI

extension EnvironmentValues {

  /// Whether ``DifferentRequestsView`` already draws Close above this screen and sizes the sheet,
  /// as it does on macOS.
  @Entry var requestsSheet = RequestsSheetPresence()
}
