import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/config/firebase_environment_config.dart';

void main() {
  group('FirebaseEnvironmentConfig', () {
    test('reports every missing required value', () {
      const config = FirebaseEnvironmentConfig(
        apiKey: '',
        appId: '',
        messagingSenderId: '',
        projectId: '',
      );

      expect(
        config.missingKeys,
        containsAll([
          'FIREBASE_API_KEY',
          'FIREBASE_APP_ID',
          'FIREBASE_MESSAGING_SENDER_ID',
          'FIREBASE_PROJECT_ID',
        ]),
      );
      expect(config.isComplete, isFalse);
    });

    test('creates FirebaseOptions only from supplied values', () {
      const config = FirebaseEnvironmentConfig(
        apiKey: 'api-key',
        appId: 'app-id',
        messagingSenderId: 'sender-id',
        projectId: 'project-id',
        authDomain: '',
        storageBucket: 'bucket.example',
      );

      final options = config.toFirebaseOptions();

      expect(config.isComplete, isTrue);
      expect(options.apiKey, 'api-key');
      expect(options.appId, 'app-id');
      expect(options.projectId, 'project-id');
      expect(options.authDomain, isNull);
      expect(options.storageBucket, 'bucket.example');
    });
  });
}
