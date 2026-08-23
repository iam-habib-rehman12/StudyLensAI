import 'package:flutter/material.dart';

abstract final class AppColors {
  static const seed = Color(0xFF5356CF);
  static const indigo = Color(0xFF5356CF);
  static const violet = Color(0xFF7C4DFF);
  static const cyan = Color(0xFF22A9C5);
  static const success = Color(0xFF16865C);
  static const warning = Color(0xFFE29B25);
  static const lightSurface = Color(0xFFF7F7FC);
  static const darkSurface = Color(0xFF11121A);

  static const askGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, violet],
  );
}
