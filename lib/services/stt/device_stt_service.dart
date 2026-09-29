import 'dart:async';
import 'dart:developer' as dev;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'stt_service.dart';

/// Real on-device Speech-to-Text service utilizing device acoustic engine.
class DeviceSttService implements SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _soundLevelController = StreamController<double>.broadcast();
  final _hypothesisController = StreamController<String>.broadcast();

  bool _isInitialized = false;
  bool _isListening = false;
  String _finalTranscription = '';

  @override
  bool get isListening => _isListening;

  @override
  Stream<double> get soundLevelStream => _soundLevelController.stream;

  @override
  Stream<String> get partialHypothesisStream => _hypothesisController.stream;

  Future<bool> _initSpeech() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          dev.log('[DeviceSttService] Error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (String status) {
          dev.log('[DeviceSttService] Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      dev.log('[DeviceSttService] Initialization failed: $e');
      return false;
    }
  }

  String _mapLocale(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'hi_IN';
      case 'te':
        return 'te_IN';
      case 'ta':
        return 'ta_IN';
      case 'kn':
        return 'kn_IN';
      case 'ml':
        return 'ml_IN';
      case 'mr':
        return 'mr_IN';
      case 'gu':
        return 'gu_IN';
      case 'bn':
        return 'bn_IN';
      case 'or':
        return 'or_IN';
      case 'en':
      default:
        return 'en_IN';
    }
  }

  @override
  Future<void> startListening({
    required String languageCode,
    void Function(double level)? onSoundLevelChanged,
  }) async {
    _finalTranscription = '';
    _isListening = true;

    final available = await _initSpeech();
    if (!available) {
      dev.log('[DeviceSttService] Speech recognition engine unavailable.');
      _hypothesisController.add('Microphone listening...');
      return;
    }

    final localeId = _mapLocale(languageCode);

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        ),
        onSoundLevelChange: (level) {
          // Normalize level (speech_to_text dB value to 0.0 - 1.0)
          final normalized = ((level + 2.0) / 12.0).clamp(0.0, 1.0);
          _soundLevelController.add(normalized);
          onSoundLevelChanged?.call(normalized);
        },
        onResult: (SpeechRecognitionResult result) {
          _finalTranscription = result.recognizedWords;
          _hypothesisController.add(_finalTranscription);
        },
      );
    } catch (e) {
      dev.log('[DeviceSttService] Listen exception: $e');
    }
  }

  @override
  Future<String> stopListening() async {
    _isListening = false;
    _soundLevelController.add(0.0);

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      dev.log('[DeviceSttService] Stop exception: $e');
    }

    return _finalTranscription.trim();
  }

  @override
  Future<void> cancel() async {
    _isListening = false;
    _soundLevelController.add(0.0);
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  void dispose() {
    _soundLevelController.close();
    _hypothesisController.close();
  }
}
