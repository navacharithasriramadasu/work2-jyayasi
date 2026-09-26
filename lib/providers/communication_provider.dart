import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/connection_model.dart';
import '../models/message_model.dart';
import 'connection_provider.dart';
import 'language_provider.dart';
import 'message_provider.dart';
import 'service_providers.dart';

class CommunicationStateModel {
  final CommunicationState state;
  final String currentText;
  final String interimHypothesis;
  final double soundLevel;
  final int processingStep; // 0 to 3
  final MessageModel? activeMessage;
  final MessageModel? incomingMessage;
  final String? errorMessage;
  final bool isAudioPlaybackActive;

  const CommunicationStateModel({
    this.state = CommunicationState.idle,
    this.currentText = '',
    this.interimHypothesis = '',
    this.soundLevel = 0.0,
    this.processingStep = 0,
    this.activeMessage,
    this.incomingMessage,
    this.errorMessage,
    this.isAudioPlaybackActive = false,
  });

  bool get isIdle => state == CommunicationState.idle;
  bool get isListening => state == CommunicationState.listening;
  bool get isProcessing => state == CommunicationState.processing;
  bool get isMessageReady => state == CommunicationState.messageReady;
  bool get isSending => state == CommunicationState.sending;
  bool get isSent => state == CommunicationState.sent;
  bool get isReceiving =>
      state == CommunicationState.receiving || state == CommunicationState.speaking;
  bool get isSpeaking => state == CommunicationState.speaking;

  CommunicationStateModel copyWith({
    CommunicationState? state,
    String? currentText,
    String? interimHypothesis,
    double? soundLevel,
    int? processingStep,
    MessageModel? activeMessage,
    MessageModel? incomingMessage,
    String? errorMessage,
    bool? isAudioPlaybackActive,
    bool clearActiveMessage = false,
    bool clearIncomingMessage = false,
  }) {
    return CommunicationStateModel(
      state: state ?? this.state,
      currentText: currentText ?? this.currentText,
      interimHypothesis: interimHypothesis ?? this.interimHypothesis,
      soundLevel: soundLevel ?? this.soundLevel,
      processingStep: processingStep ?? this.processingStep,
      activeMessage:
          clearActiveMessage ? null : (activeMessage ?? this.activeMessage),
      incomingMessage: clearIncomingMessage
          ? null
          : (incomingMessage ?? this.incomingMessage),
      errorMessage: errorMessage,
      isAudioPlaybackActive:
          isAudioPlaybackActive ?? this.isAudioPlaybackActive,
    );
  }
}

class CommunicationNotifier extends Notifier<CommunicationStateModel> {
  static const _uuid = Uuid();
  StreamSubscription? _soundSub;
  StreamSubscription? _hypoSub;
  StreamSubscription? _incomingSub;
  StreamSubscription? _ttsSub;

  @override
  CommunicationStateModel build() {
    _initStreams();
    ref.onDispose(() {
      _soundSub?.cancel();
      _hypoSub?.cancel();
      _incomingSub?.cancel();
      _ttsSub?.cancel();
    });
    return const CommunicationStateModel();
  }

  void _initStreams() {
    final stt = ref.read(sttServiceProvider);
    _soundSub = stt.soundLevelStream.listen((level) {
      if (state.isListening) {
        state = state.copyWith(soundLevel: level);
      }
    });

    _hypoSub = stt.partialHypothesisStream.listen((hypothesis) {
      if (state.isListening) {
        state = state.copyWith(interimHypothesis: hypothesis);
      }
    });

    final commService = ref.read(communicationServiceProvider);
    _incomingSub = commService.incomingMessages.listen((message) {
      onMessageReceived(message);
    });

    final tts = ref.read(ttsServiceProvider);
    _ttsSub = tts.isSpeakingStream.listen((isSpeaking) {
      state = state.copyWith(isAudioPlaybackActive: isSpeaking);
    });
  }

  /// User holds or presses PTT button to start speech recognition
  Future<void> startListening() async {
    final lang = ref.read(languageProvider);
    final stt = ref.read(sttServiceProvider);

    state = state.copyWith(
      state: CommunicationState.listening,
      currentText: '',
      interimHypothesis: 'Listening for speech...',
      soundLevel: 0.1,
    );

    try {
      await stt.startListening(languageCode: lang.senderLanguage.code);
    } catch (e) {
      state = state.copyWith(
        state: CommunicationState.error,
        errorMessage: 'Microphone capture failed: $e',
      );
    }
  }

  /// User releases PTT button -> pause detected -> local speech recognition
  Future<void> stopListeningAndProcess() async {
    if (!state.isListening) return;

    state = state.copyWith(
      state: CommunicationState.processing,
      processingStep: 0,
    );

    final stt = ref.read(sttServiceProvider);
    final text = await stt.stopListening();

    // Animate pipeline steps (Pause detection -> local STT -> preparing message)
    state = state.copyWith(processingStep: 1, currentText: text);
    await Future.delayed(const Duration(milliseconds: 350));
    state = state.copyWith(processingStep: 2);
    await Future.delayed(const Duration(milliseconds: 350));
    state = state.copyWith(processingStep: 3);
    await Future.delayed(const Duration(milliseconds: 250));

    // Transition to messageReady state
    state = state.copyWith(
      state: CommunicationState.messageReady,
      currentText: text.isNotEmpty ? text : 'Send the location to the rescue team.',
    );
  }

  /// Cancel listening and return to idle
  Future<void> cancelListening() async {
    final stt = ref.read(sttServiceProvider);
    await stt.cancel();
    state = state.copyWith(
      state: CommunicationState.idle,
      currentText: '',
      interimHypothesis: '',
      soundLevel: 0.0,
      processingStep: 0,
    );
  }

  /// Send message as compact text over Wi-Fi Direct / Bluetooth
  Future<void> sendMessage() async {
    final lang = ref.read(languageProvider);
    final conn = ref.read(connectionProvider);
    final remoteDevice = conn.connectedDevice?.name ?? 'iTantra-Rescue-01';

    final textToSend = state.currentText.isNotEmpty
        ? state.currentText
        : 'Send the location to the rescue team.';

    final message = MessageModel(
      id: _uuid.v4(),
      text: textToSend,
      sender: 'You',
      receiver: remoteDevice,
      timestamp: DateTime.now(),
      language: lang.pairLabel,
      status: MessageStatus.sending,
      isEmergency: false,
      connectionType: conn.preferredTransport,
    );

    state = state.copyWith(
      state: CommunicationState.sending,
      activeMessage: message,
    );

    // Add to message list
    ref.read(messageListProvider.notifier).addMessage(message);

    final commService = ref.read(communicationServiceProvider);
    await commService.sendMessage(message);

    // Update status to delivered/sent
    final deliveredMessage = message.copyWith(status: MessageStatus.delivered);
    ref.read(messageListProvider.notifier).updateStatus(
          message.id,
          MessageStatus.delivered,
        );

    state = state.copyWith(
      state: CommunicationState.sent,
      activeMessage: deliveredMessage,
    );

    // Auto-schedule realistic remote transceiver response for interactive demo
    ref.read(demoSimulationServiceProvider).scheduleSimulatedRemoteResponse(
          promptResponse: 'Message received. Location confirmed. Stand by.',
          senderName: remoteDevice,
          languagePair: '${lang.receiverLanguage.englishName} → ${lang.senderLanguage.englishName}',
        );
  }

  /// Speak again: returns to listening or idle
  void speakAgain() {
    state = state.copyWith(
      state: CommunicationState.idle,
      currentText: '',
      interimHypothesis: '',
    );
  }

  /// Handle incoming message from remote node
  void onMessageReceived(MessageModel message) {
    ref.read(messageListProvider.notifier).addMessage(message);

    state = state.copyWith(
      state: CommunicationState.receiving,
      incomingMessage: message,
    );

    // Convert text to speech locally
    Future.delayed(const Duration(milliseconds: 600), () {
      speakIncomingMessage(message.text);
    });
  }

  /// Play incoming message via local TTS
  Future<void> speakIncomingMessage(String text) async {
    state = state.copyWith(state: CommunicationState.speaking);
    final lang = ref.read(languageProvider);
    final tts = ref.read(ttsServiceProvider);
    await tts.speak(text, languageCode: lang.senderLanguage.code);
  }

  /// Stop active TTS
  Future<void> stopSpeaking() async {
    final tts = ref.read(ttsServiceProvider);
    await tts.stop();
    state = state.copyWith(
      state: CommunicationState.receiving,
      isAudioPlaybackActive: false,
    );
  }

  /// Replay active incoming speech
  Future<void> replayIncoming() async {
    if (state.incomingMessage != null) {
      await speakIncomingMessage(state.incomingMessage!.text);
    }
  }

  /// Reset to idle
  void resetToIdle() {
    state = state.copyWith(
      state: CommunicationState.idle,
      currentText: '',
      interimHypothesis: '',
      soundLevel: 0.0,
      processingStep: 0,
      clearActiveMessage: true,
      clearIncomingMessage: true,
    );
  }
}

final communicationProvider =
    NotifierProvider<CommunicationNotifier, CommunicationStateModel>(
  CommunicationNotifier.new,
);
