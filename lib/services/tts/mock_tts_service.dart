import 'dart:async';
import 'tts_service.dart';

/// Realistic mock implementation of On-Device TTS.
/// Simulates speech synthesis and active speaker audio playback.
class MockTtsService implements TtsService {
  final _speakingController = StreamController<bool>.broadcast();
  bool _isSpeaking = false;
  Timer? _speechDurationTimer;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<bool> get isSpeakingStream => _speakingController.stream;

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    // Stop any current playback
    await stop();

    _isSpeaking = true;
    _speakingController.add(true);

    // Calculate approximate duration based on word count (min 2.5s, max 6s)
    final words = text.split(' ').length;
    final durationMs = (words * 320).clamp(2500, 6000);

    _speechDurationTimer = Timer(Duration(milliseconds: durationMs), () {
      _isSpeaking = false;
      _speakingController.add(false);
    });
  }

  @override
  Future<void> stop() async {
    _speechDurationTimer?.cancel();
    if (_isSpeaking) {
      _isSpeaking = false;
      _speakingController.add(false);
    }
  }

  void dispose() {
    _speechDurationTimer?.cancel();
    _speakingController.close();
  }
}
