/// Abstract interface for On-Device Speech-to-Text engine.
/// Implementations can wrap on-device Whisper, Vosk, or Sherpa-ONNX.
abstract class SttService {
  /// Start capturing voice on microphone.
  Future<void> startListening({
    required String languageCode,
    void Function(double level)? onSoundLevelChanged,
  });

  /// Stop capturing, complete pause-detection, and return transcribed text.
  Future<String> stopListening();

  /// Cancel listening without producing a transcription.
  Future<void> cancel();

  /// Stream of normalized sound level (0.0 to 1.0) for live waveform visualization.
  Stream<double> get soundLevelStream;

  /// Stream of partial interim recognition hypothesis.
  Stream<String> get partialHypothesisStream;

  /// Whether the engine is currently listening.
  bool get isListening;
}
