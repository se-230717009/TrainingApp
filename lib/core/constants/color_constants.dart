/// lib/core/constants/color_constants.dart
///
/// Central colour palette for the application.
/// All UI code should reference these constants rather than hard-coding
/// hex values inline, so a theme change only requires updating this file.
library;
import 'package:flutter/material.dart';

/// Application-wide colour constants.
class ColorConstants {
  // Private constructor — this class should never be instantiated.
  ColorConstants._();

  /// Primary brand colour — a vibrant cyan used for buttons, highlights,
  /// and accent elements throughout the app.
  static const Color primaryColor = Color.fromARGB(255, 16, 225, 225);

  /// Secondary accent colour — a warm coral/pink used for decorative elements.
  static const Color secondaryColor = Color(0xFFFF6584);

  /// Default page background colour for light-mode surfaces.
  /// Uses an off-white instead of pure white to reduce eye strain.
  static const Color backgroundColor = Color(0xFFF9F9F9);

  /// Surface colour for cards and elevated components.
  static const Color surfaceColor = Colors.white;

  /// Primary text colour — dark navy-grey, softer than pure black.
  static const Color textPrimary = Color(0xFF2D3142);

  /// Secondary / hint text colour — muted purple-grey.
  static const Color textSecondary = Color(0xFF9C9DB9);

  /// Background fill colour for text input fields.
  static const Color inputFill = Color(0xFFF0F0F5);
}
