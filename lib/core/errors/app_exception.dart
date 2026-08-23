enum AppErrorType {
  configuration,
  authentication,
  permissionDenied,
  offline,
  invalidDocument,
  malformedResponse,
  rateLimited,
  persistence,
  unknown,
}

class FirebaseConfigurationException extends AppException {
  FirebaseConfigurationException(this.missingKeys)
    : super(
        type: AppErrorType.configuration,
        message:
            'Firebase configuration is required before StudyLens can start.',
      );

  final List<String> missingKeys;
}

class AppException implements Exception {
  const AppException({required this.type, required this.message, this.cause});

  final AppErrorType type;
  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException($type, $message)';
}
