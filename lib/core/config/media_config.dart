abstract final class MediaConfig {
  static const imageMaxBytes = 12 * 1024 * 1024;
  static const imageMaxDimension = 2400.0;
  static const imageQuality = 90;

  /// Leaves room for inline-data base64 expansion (about 13.3 MB) under
  /// Gemini's 20 MB request limit.
  static const pdfMaxMegabytes = 10;
  static const pdfMaxBytes = pdfMaxMegabytes * 1024 * 1024;
}
