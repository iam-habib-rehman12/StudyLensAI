import 'package:flutter/material.dart';

class OverviewLoading extends StatelessWidget {
  const OverviewLoading({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 14),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}

class OverviewFailure extends StatelessWidget {
  const OverviewFailure({
    required this.message,
    required this.isOffline,
    required this.onRetry,
    super.key,
  });

  final String message;
  final bool isOffline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
            color: colors.onErrorContainer,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onErrorContainer),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
