import CoreGraphics

/// The smallest a full SDK screen is drawn on macOS: room for the bar's buttons on one line and a
/// screenful of rows.
enum SheetMinimumSize: CGFloat {

  case width = 520

  case height = 600
}
