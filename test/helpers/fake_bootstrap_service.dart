import 'package:studylens_ai/features/bootstrap/domain/bootstrap_service.dart';

class FakeBootstrapService implements BootstrapService {
  FakeBootstrapService({this.onInitialize});

  final Future<void> Function()? onInitialize;
  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
    await onInitialize?.call();
  }
}
