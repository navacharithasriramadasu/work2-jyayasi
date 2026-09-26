import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/connection_model.dart';
import '../models/device_model.dart';
import '../models/message_model.dart';
import 'connection_provider.dart';
import 'language_provider.dart';
import 'message_provider.dart';
import 'service_providers.dart';

class EmergencyStateModel {
  final EmergencyState state;
  final String activeMessageText;
  final MessageModel? sentEmergencyMessage;
  final MessageModel? receivedEmergencyMessage;
  final bool isSpeaking;

  const EmergencyStateModel({
    this.state = EmergencyState.idle,
    this.activeMessageText = 'Medical emergency. Immediate assistance required.',
    this.sentEmergencyMessage,
    this.receivedEmergencyMessage,
    this.isSpeaking = false,
  });

  bool get isArmed => isConfirming;
  bool get isConfirming => state == EmergencyState.confirming;
  bool get isSending => state == EmergencyState.sending;
  bool get isSent => state == EmergencyState.sent;
  bool get isReceived => state == EmergencyState.received;

  EmergencyStateModel copyWith({
    EmergencyState? state,
    String? activeMessageText,
    MessageModel? sentEmergencyMessage,
    MessageModel? receivedEmergencyMessage,
    bool? isSpeaking,
    bool clearSentMessage = false,
    bool clearReceivedMessage = false,
  }) {
    return EmergencyStateModel(
      state: state ?? this.state,
      activeMessageText: activeMessageText ?? this.activeMessageText,
      sentEmergencyMessage: clearSentMessage
          ? null
          : (sentEmergencyMessage ?? this.sentEmergencyMessage),
      receivedEmergencyMessage: clearReceivedMessage
          ? null
          : (receivedEmergencyMessage ?? this.receivedEmergencyMessage),
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

class EmergencyNotifier extends Notifier<EmergencyStateModel> {
  static const _uuid = Uuid();

  @override
  EmergencyStateModel build() {
    return const EmergencyStateModel();
  }

  void selectPreset(String text) {
    state = state.copyWith(activeMessageText: text);
  }

  void arm(String text) {
    state = state.copyWith(
      state: EmergencyState.confirming,
      activeMessageText: text,
    );
  }

  Future<void> confirmAndSend() async {
    final lang = ref.read(languageProvider);
    final conn = ref.read(connectionProvider);
    final remoteDevice = conn.connectedDevice?.name ?? 'iTantra-Rescue-01';

    final emergencyMessage = MessageModel(
      id: _uuid.v4(),
      text: state.activeMessageText,
      sender: 'You',
      receiver: remoteDevice,
      timestamp: DateTime.now(),
      language: lang.pairLabel,
      status: MessageStatus.sending,
      isEmergency: true,
      connectionType: conn.preferredTransport,
    );

    state = state.copyWith(
      state: EmergencyState.sending,
      sentEmergencyMessage: emergencyMessage,
    );

    ref.read(messageListProvider.notifier).addMessage(emergencyMessage);

    final comm = ref.read(communicationServiceProvider);
    await comm.sendMessage(emergencyMessage);

    final delivered = emergencyMessage.copyWith(status: MessageStatus.delivered);
    ref.read(messageListProvider.notifier).updateStatus(
          emergencyMessage.id,
          MessageStatus.delivered,
        );

    state = state.copyWith(
      state: EmergencyState.sent,
      sentEmergencyMessage: delivered,
    );
  }

  void simulateReceiveEmergency({
    required String text,
    required String sender,
  }) {
    final lang = ref.read(languageProvider);
    final msg = MessageModel(
      id: _uuid.v4(),
      text: text,
      sender: sender,
      receiver: 'You',
      timestamp: DateTime.now(),
      language: '${lang.receiverLanguage.englishName} → ${lang.senderLanguage.englishName}',
      status: MessageStatus.received,
      isEmergency: true,
      connectionType: ConnectionType.wifiDirect,
    );

    ref.read(messageListProvider.notifier).addMessage(msg);

    state = state.copyWith(
      state: EmergencyState.received,
      receivedEmergencyMessage: msg,
      isSpeaking: true,
    );

    final tts = ref.read(ttsServiceProvider);
    tts.speak('Priority alert: $text', languageCode: lang.senderLanguage.code);
  }

  Future<void> replay() async {
    if (state.receivedEmergencyMessage != null) {
      final lang = ref.read(languageProvider);
      final tts = ref.read(ttsServiceProvider);
      state = state.copyWith(isSpeaking: true);
      await tts.speak(
        'Priority alert: ${state.receivedEmergencyMessage!.text}',
        languageCode: lang.senderLanguage.code,
      );
    }
  }

  void acknowledge() {
    final tts = ref.read(ttsServiceProvider);
    tts.stop();
    state = state.copyWith(
      state: EmergencyState.idle,
      isSpeaking: false,
      clearReceivedMessage: true,
      clearSentMessage: true,
    );
  }

  void cancel() {
    state = state.copyWith(state: EmergencyState.idle);
  }
}

final emergencyProvider =
    NotifierProvider<EmergencyNotifier, EmergencyStateModel>(
  EmergencyNotifier.new,
);
