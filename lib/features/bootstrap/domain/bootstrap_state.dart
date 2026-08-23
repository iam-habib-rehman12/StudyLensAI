enum BootstrapStatus { initial, loading, ready, configurationRequired, failure }

class BootstrapState {
  const BootstrapState({
    required this.status,
    this.message,
    this.missingConfigurationKeys = const [],
  });

  const BootstrapState.initial() : this(status: BootstrapStatus.initial);

  final BootstrapStatus status;
  final String? message;
  final List<String> missingConfigurationKeys;
}
