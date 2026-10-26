/// The numbers relative luminance is computed from, over linear color components.
enum LuminanceWeight: Float {

  case red = 0.2126

  case green = 0.7152

  case blue = 0.0722

  /// The luminance above which white on a color measures under 4.5 to 1 and black measures over it.
  case blackContrastThreshold = 0.183
}
