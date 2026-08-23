import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../application/scan_controller.dart';
import '../application/scan_state.dart';
import '../domain/study_image.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({required this.controller, super.key});

  final ScanController controller;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return Scaffold(
          appBar: AppBar(title: const Text('Scan & Learn')),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (state.isBusy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: state.image == null
                        ? _IntakeView(
                            key: const ValueKey('intake'),
                            state: state,
                            controller: widget.controller,
                          )
                        : _PreviewView(
                            key: const ValueKey('preview'),
                            state: state,
                            controller: widget.controller,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IntakeView extends StatelessWidget {
  const _IntakeView({required this.state, required this.controller, super.key});

  final ScanState state;
  final ScanController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  gradient: AppColors.askGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withValues(alpha: 0.2),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bring your learning material into focus',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Photograph notes, equations, diagrams, textbook pages, or choose an existing image.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              if (state.message case final message?) ...[
                _IssueCard(
                  message: message,
                  requiresSettings: state.requiresSettings,
                  onSettings: controller.openSettings,
                  onDismiss: controller.clearIssue,
                ),
                const SizedBox(height: 16),
              ],
              _SourceCard(
                icon: Icons.photo_camera_rounded,
                color: AppColors.indigo,
                title: 'Take a photo',
                description: 'Open the camera and capture material now.',
                buttonLabel: 'Open camera',
                enabled: !state.isBusy,
                onPressed: controller.capture,
              ),
              const SizedBox(height: 14),
              _SourceCard(
                icon: Icons.photo_library_rounded,
                color: AppColors.cyan,
                title: 'Choose from gallery',
                description:
                    'Select an educational image already on your phone.',
                buttonLabel: 'Choose image',
                outlined: true,
                enabled: !state.isBusy,
                onPressed: controller.selectFromGallery,
              ),
              const SizedBox(height: 18),
              const _LocalOnlyNotice(),
              if (state.isBusy) ...[
                const SizedBox(height: 22),
                Text(
                  _busyLabel(state.status),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _busyLabel(ScanStatus status) => switch (status) {
    ScanStatus.recovering => 'Checking for an interrupted image selection...',
    ScanStatus.requestingPermission => 'Checking camera access...',
    ScanStatus.selecting => 'Opening image source...',
    ScanStatus.ready || ScanStatus.preview => '',
  };
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.state,
    required this.controller,
    super.key,
  });

  final ScanState state;
  final ScanController controller;

  @override
  Widget build(BuildContext context) {
    final image = state.image!;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image preview',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check that the material is clear and readable.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      image.source == StudyImageSource.camera
                          ? Icons.photo_camera_rounded
                          : Icons.photo_library_rounded,
                      size: 17,
                    ),
                    label: Text(image.source.label),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ColoredBox(
                  color: Colors.black,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 240,
                      maxHeight: 500,
                    ),
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.memory(
                          image.bytes,
                          key: const Key('scan-image-preview'),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white70,
                                    size: 46,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'This image cannot be previewed.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.image_outlined, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      image.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatBytes(image.byteLength),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (state.message case final message?) ...[
                const SizedBox(height: 16),
                _IssueCard(
                  message: message,
                  requiresSettings: state.requiresSettings,
                  onSettings: controller.openSettings,
                  onDismiss: controller.clearIssue,
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: state.isBusy ? null : controller.retake,
                icon: Icon(
                  image.source == StudyImageSource.camera
                      ? Icons.replay_rounded
                      : Icons.photo_library_rounded,
                ),
                label: Text(
                  image.source == StudyImageSource.camera
                      ? 'Retake photo'
                      : 'Choose another image',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : controller.discard,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Discard image'),
              ),
              const SizedBox(height: 18),
              const _LocalOnlyNotice(
                message:
                    'This preview stays in memory only. Image analysis will use these bytes directly without requiring Cloud Storage.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.enabled,
    required this.onPressed,
    this.outlined = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String buttonLabel;
  final bool enabled;
  final Future<void> Function() onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = outlined
        ? OutlinedButton.icon(
            onPressed: enabled ? onPressed : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(buttonLabel),
          )
        : FilledButton.icon(
            onPressed: enabled ? onPressed : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(buttonLabel),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            button,
          ],
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.message,
    required this.requiresSettings,
    required this.onSettings,
    required this.onDismiss,
  });

  final String message;
  final bool requiresSettings;
  final Future<void> Function() onSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 8, 14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          if (requiresSettings)
            TextButton(onPressed: onSettings, child: const Text('Settings'))
          else
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss message',
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _LocalOnlyNotice extends StatelessWidget {
  const _LocalOnlyNotice({
    this.message =
        'Images remain local to this screen. StudyLens does not require Cloud Storage for this workflow.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.phonelink_lock_rounded,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
