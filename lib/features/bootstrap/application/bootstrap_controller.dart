import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/bootstrap_service.dart';
import '../domain/bootstrap_state.dart';

class BootstrapController extends ChangeNotifier {
  BootstrapController(this._service);

  final BootstrapService _service;
  BootstrapState _state = const BootstrapState.initial();
  bool _requestInProgress = false;

  BootstrapState get state => _state;

  Future<void> initialize() async {
    if (_requestInProgress || _state.status == BootstrapStatus.ready) return;

    _requestInProgress = true;
    _setState(const BootstrapState(status: BootstrapStatus.loading));

    try {
      await _service.initialize();
      _setState(const BootstrapState(status: BootstrapStatus.ready));
    } on FirebaseConfigurationException catch (error) {
      _setState(
        BootstrapState(
          status: BootstrapStatus.configurationRequired,
          message: error.message,
          missingConfigurationKeys: error.missingKeys,
        ),
      );
    } on AppException catch (error) {
      _setState(
        BootstrapState(status: BootstrapStatus.failure, message: error.message),
      );
    } catch (_) {
      _setState(
        const BootstrapState(
          status: BootstrapStatus.failure,
          message: 'StudyLens could not start. Please try again.',
        ),
      );
    } finally {
      _requestInProgress = false;
    }
  }

  void _setState(BootstrapState value) {
    _state = value;
    notifyListeners();
  }
}
