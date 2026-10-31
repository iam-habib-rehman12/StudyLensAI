import 'dart:developer' as developer;

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
      // Android is the shipping target. The web build is a local preview and
      // does not configure a web App Check provider.
      if (!kIsWeb) {
        try {
          final useDebugProvider = kDebugMode || config.useDebugAppCheck;
          final debugToken = config.debugAppCheckToken.trim();
          await FirebaseAppCheck.instance.activate(
            providerAndroid: useDebugProvider
                ? AndroidDebugProvider(
                    debugToken: debugToken.isEmpty ? null : debugToken,
                  )
                : const AndroidPlayIntegrityProvider(),
          );
        } catch (error, stackTrace) {
          // App Check failures must not block Auth/Firestore startup. AI calls
          // will surface their own App Check error if enforcement is enabled.
          developer.log(
            'App Check activation failed; continuing without it.',
            name: 'studylens.bootstrap',
            error: error,
            stackTrace: stackTrace,
            level: 900,
          );
        }
      }

      if (config.useEmulators) {
        await FirebaseAuth.instance.useAuthEmulator(config.emulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(
          config.emulatorHost,
          8080,
        );
      }

      if (!kIsWeb) {
        // Firestore persistence is device-wide. Clear documents cached by a
        // previous process so a different student on a shared device cannot see
        // stale local data.
        try {
          await FirebaseFirestore.instance.clearPersistence();
        } on FirebaseException catch (error, stackTrace) {
          developer.log(
            'Clearing Firestore persistence failed; continuing.',
            name: 'studylens.bootstrap',
            error: error,
            stackTrace: stackTrace,
            level: 900,
          );
        }

        try {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: true,
          );
        } on FirebaseException catch (error, stackTrace) {
          developer.log(
            'Enabling Firestore persistence failed; continuing.',
            name: 'studylens.bootstrap',
            error: error,
            stackTrace: stackTrace,
            level: 900,
          );
        }
      }
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Firebase bootstrap failed: ${error.code}',
        name: 'studylens.bootstrap',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      throw AppException(
        type: AppErrorType.persistence,
        message:
            'StudyLens could not connect to Firebase. Check your connection and Firebase project setup, then try again.',
        cause: error,
      );
    }
  }
}
