import 'package:intl/intl.dart';

/// Formatting helpers for technical and message displays.
class Formatters {
  Formatters._();

  static String time(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String fullDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  static String signalStrength(double strength) {
    if (strength >= 0.8) return 'Strong';
    if (strength >= 0.5) return 'Medium';
    if (strength >= 0.2) return 'Weak';
    return 'Very Weak';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
