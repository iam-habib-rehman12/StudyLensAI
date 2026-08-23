import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/firebase_environment_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/bootstrap_service.dart';

class FirebaseBootstrapService implements BootstrapService {
  FirebaseBootstrapService({required this.config});

  final FirebaseEnvironmentConfig config;

  @override
  Future<void> initialize() async {
    if (!config.isComplete) {
      throw FirebaseConfigurationException(config.missingKeys);
    }

    try {
      await Firebase.initializeApp(options: config.toFirebaseOptions());
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );

      if (config.useEmulators) {
        await FirebaseAuth.instance.useAuthEmulator(config.emulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(
          config.emulatorHost,
          8080,
        );
      }

      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    } on FirebaseException catch (error) {
      throw AppException(
        type: AppErrorType.persistence,
        message: 'StudyLens could not connect to Firebase. Please try again.',
        cause: error,
      );
    }
  }
}
