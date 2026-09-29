import '../../models/language_model.dart';

/// Core application constants for iTantra Voice Transceiver.
class AppConstants {
  AppConstants._();

  static const String appName = 'iTantra';
  static const String appSubTitle = 'Voice Transceiver';
  static const String appTagline = 'Voice communication without transmitting voice.';
  static const String appDescription =
      'Offline AI • Multilingual • Low-Bandwidth';
  static const String version = 'iTantra 1.0';

  // 8-point Spacing System
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Corner Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 18.0;

  // Default Tactical Channel
  static const String defaultDeviceId = 'ITANTRA-NODE-01';
  static const String defaultDeviceName = 'COMMAND_NET (434.25 MHz)';

  // Supported Languages (10 Indian languages + English with native scripts)
  static const List<LanguageModel> supportedLanguages = [
    LanguageModel(code: 'en', englishName: 'English', nativeName: 'English'),
    LanguageModel(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
    LanguageModel(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు'),
    LanguageModel(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்'),
    LanguageModel(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    LanguageModel(code: 'ml', englishName: 'Malayalam', nativeName: 'മലയാളം'),
    LanguageModel(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी'),
    LanguageModel(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી'),
    LanguageModel(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা'),
    LanguageModel(code: 'or', englishName: 'Odia', nativeName: 'ଓଡ଼ିଆ'),
  ];

  // Predefined Emergency Messages
  static const List<String> emergencyPresets = [
    'I need immediate assistance.',
    'Medical emergency. Immediate assistance required.',
    'Rescue team needed at current coordinates.',
    'Location required. Evacuation in progress.',
    'Danger: structural collapse risk detected.',
  ];
}
