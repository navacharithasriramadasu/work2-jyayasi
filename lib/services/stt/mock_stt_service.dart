import 'dart:async';
import 'dart:math';
import 'stt_service.dart';

/// Realistic mock implementation of On-Device STT.
/// Simulates voice waveform, pause detection, and on-device transcription.
class MockSttService implements SttService {
  final _soundLevelController = StreamController<double>.broadcast();
  final _hypothesisController = StreamController<String>.broadcast();
  Timer? _waveformTimer;
  bool _isListening = false;
  int _sampleIndex = 0;

  final List<String> _cannedPhrases = [
    'Send the location to the rescue team.',
    'Medical assistance required at grid sector four.',
    'Water level rising in south channel, need immediate support.',
    'All personnel reported safe at primary check-post.',
    'Clear transmission received. Standing by for coordinates.',
  ];

  @override
  bool get isListening => _isListening;

  @override
  Stream<double> get soundLevelStream => _soundLevelController.stream;

  @override
  Stream<String> get partialHypothesisStream => _hypothesisController.stream;

  @override
  Future<void> startListening({
    required String languageCode,
    void Function(double level)? onSoundLevelChanged,
  }) async {
    _isListening = true;
    final random = Random();

    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!_isListening) return;
      // Generate dynamic waveform levels
      final level = 0.25 + (0.75 * random.nextDouble());
      _soundLevelController.add(level);
      onSoundLevelChanged?.call(level);
    });

    // Simulate interim partial speech recognition
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isListening) _hypothesisController.add('Send...');
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_isListening) _hypothesisController.add('Send the location...');
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_isListening) {
        _hypothesisController.add('Send the location to the rescue team...');
      }
    });
  }

  @override
  Future<String> stopListening() async {
    _isListening = false;
    _waveformTimer?.cancel();
    _soundLevelController.add(0.0);

    // Simulate on-device pause detection and inference latency (350ms)
    await Future.delayed(const Duration(milliseconds: 400));

    final phrase = _cannedPhrases[_sampleIndex % _cannedPhrases.length];
    _sampleIndex++;
    return phrase;
  }

  @override
  Future<void> cancel() async {
    _isListening = false;
    _waveformTimer?.cancel();
    _soundLevelController.add(0.0);
  }

  void dispose() {
    _waveformTimer?.cancel();
    _soundLevelController.close();
    _hypothesisController.close();
  }
}
