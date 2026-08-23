import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'StudyLens AI logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.indigo, AppColors.violet],
          ),
          borderRadius: BorderRadius.circular(size * 0.29),
          boxShadow: [
            BoxShadow(
              color: AppColors.indigo.withValues(alpha: 0.25),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.12),
            ),
          ],
        ),
        child: Icon(
          Icons.auto_stories_rounded,
          color: Colors.white,
          size: size * 0.52,
        ),
      ),
    );
  }
}
