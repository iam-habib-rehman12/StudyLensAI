import 'package:firebase_core/firebase_core.dart';

class FirebaseEnvironmentConfig {
  const FirebaseEnvironmentConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    this.storageBucket,
    this.useEmulators = false,
    this.emulatorHost = '10.0.2.2',
  });

  factory FirebaseEnvironmentConfig.fromEnvironment() {
    return const FirebaseEnvironmentConfig(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      useEmulators: bool.fromEnvironment('USE_FIREBASE_EMULATORS'),
      emulatorHost: String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
        defaultValue: '10.0.2.2',
      ),
    );
  }

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String? storageBucket;
  final bool useEmulators;
  final String emulatorHost;

  List<String> get missingKeys {
    return [
      if (apiKey.trim().isEmpty) 'FIREBASE_API_KEY',
      if (appId.trim().isEmpty) 'FIREBASE_APP_ID',
      if (messagingSenderId.trim().isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
      if (projectId.trim().isEmpty) 'FIREBASE_PROJECT_ID',
    ];
  }

  bool get isComplete => missingKeys.isEmpty;

  FirebaseOptions toFirebaseOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: _valueOrNull(authDomain),
      storageBucket: _valueOrNull(storageBucket),
    );
  }

  String? _valueOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
