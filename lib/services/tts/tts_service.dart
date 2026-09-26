/// Abstract interface for On-Device Text-to-Speech synthesizer.
/// Implementations can wrap on-device Piper, Sherpa, or Android TTS.
abstract class TtsService {
  /// Synthesize and play speech from text locally.
  Future<void> speak(String text, {required String languageCode});

  /// Immediately stop ongoing speech playback.
  Future<void> stop();

  /// Whether speech playback is active.
  bool get isSpeaking;

  /// Stream of speaking state transitions.
  Stream<bool> get isSpeakingStream;
}
