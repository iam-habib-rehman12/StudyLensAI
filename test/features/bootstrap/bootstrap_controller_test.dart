import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/core/errors/app_exception.dart';
import 'package:studylens_ai/features/bootstrap/application/bootstrap_controller.dart';
import 'package:studylens_ai/features/bootstrap/domain/bootstrap_state.dart';

import '../../helpers/fake_bootstrap_service.dart';

void main() {
  test('moves to ready after successful initialization', () async {
    final service = FakeBootstrapService();
    final controller = BootstrapController(service);

    await controller.initialize();

    expect(controller.state.status, BootstrapStatus.ready);
    expect(service.initializeCalls, 1);
  });

  test('exposes missing configuration without a raw exception', () async {
    final service = FakeBootstrapService(
      onInitialize: () async {
        throw FirebaseConfigurationException(['FIREBASE_API_KEY']);
      },
    );
    final controller = BootstrapController(service);

    await controller.initialize();

    expect(controller.state.status, BootstrapStatus.configurationRequired);
    expect(controller.state.missingConfigurationKeys, ['FIREBASE_API_KEY']);
  });

  test('maps application failures to a retryable failure state', () async {
    final service = FakeBootstrapService(
      onInitialize: () async {
        throw const AppException(
          type: AppErrorType.offline,
          message: 'No connection is available.',
        );
      },
    );
    final controller = BootstrapController(service);

    await controller.initialize();

    expect(controller.state.status, BootstrapStatus.failure);
    expect(controller.state.message, 'No connection is available.');
  });

  test('prevents duplicate initialization after success', () async {
    final service = FakeBootstrapService();
    final controller = BootstrapController(service);

    await controller.initialize();
    await controller.initialize();

    expect(service.initializeCalls, 1);
  });
}
