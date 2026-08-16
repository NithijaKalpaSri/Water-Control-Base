import 'package:flutter/material.dart';

class AppColors {
  // Primary accent – cyan/teal used for highlights, progress, badges
  static const Color primaryBlue = Color(0xFF00BCD4);

  // Deep navy used for card surfaces and nav panel
  static const Color deepBlue = Color(0xFF111A35);

  // Cyan accent for water indicators
  static const Color cyan = Color(0xFF00D2FF);

  // Main scaffold background – very dark navy
  static const Color background = Color(0xFF0B1026);

  // Card / surface color – slightly lighter than background
  static const Color cardSurface = Color(0xFF111A35);

  // Subtle border color for cards
  static const Color cardBorder = Color(0xFF1A2744);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // white70
  static const Color textMuted = Color(0x80FFFFFF); // white50

  // Status colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFFEF5350);
  static const Color goodBadge = Color(0xFF00BCD4);

  // Gradient for header areas & login
  static const LinearGradient deepWaterGradient = LinearGradient(
    colors: [Color(0xFF0B1026), Color(0xFF111A35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Water fill gradient (for the water level box)
  static const LinearGradient waterFillGradient = LinearGradient(
    colors: [Color(0xFF006064), Color(0xFF00BCD4)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}
