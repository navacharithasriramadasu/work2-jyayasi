import 'package:flutter/material.dart';

/// Centralized color palette for iTantra Voice Transceiver.
/// Designed for a mission-control, tactical dark aesthetic.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color primaryBackground = Color(0xFF050A0F);
  static const Color secondaryBackground = Color(0xFF08141C);
  static const Color surface = Color(0xFF0D202B);
  static const Color elevatedSurface = Color(0xFF102A36);

  // Accents
  static const Color primaryAccent = Color(0xFF00C8F5); // Cyan
  static const Color secondaryAccent = Color(0xFF19E6C1); // Teal
  static const Color connected = Color(0xFF19E6C1); // Connected state

  // Status & Priority
  static const Color warning = Color(0xFFFFB84D); // Amber/Orange
  static const Color emergency = Color(0xFFFF4058); // Tactical Red
  static const Color emergencyDark = Color(0xFF45131C); // Deep Red

  // Text Hierarchy
  static const Color primaryText = Color(0xFFF4FAFC);
  static const Color secondaryText = Color(0xFFA2BCC9);
  static const Color mutedText = Color(0xFF7B95A2);

  // Borders & Disabled
  static const Color border = Color(0xFF173844);
  static const Color borderBright = Color(0xFF235567);
  static const Color disabled = Color(0xFF35464D);

  // Glow / Overlay utilities
  static Color primaryGlow = const Color(0xFF00C8F5).withValues(alpha: 0.35);
  static Color emergencyGlow = const Color(0xFFFF4058).withValues(alpha: 0.40);
  static Color surfaceGlass = const Color(0xFF0D202B).withValues(alpha: 0.85);
}
