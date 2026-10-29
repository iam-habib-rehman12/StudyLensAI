abstract final class MediaConfig {
  static const imageMaxBytes = 12 * 1024 * 1024;
  static const imageMaxDimension = 2400.0;
  static const imageQuality = 90;

  /// Leaves room for inline-data base64 expansion under Gemini's 20 MB
  /// request limit.
  static const pdfMaxBytes = 14 * 1024 * 1024;
}
