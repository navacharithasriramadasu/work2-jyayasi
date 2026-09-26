import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itantra_voice_transceiver/core/constants/app_constants.dart';
import 'package:itantra_voice_transceiver/models/connection_model.dart';
import 'package:itantra_voice_transceiver/models/device_model.dart';
import 'package:itantra_voice_transceiver/models/language_model.dart';
import 'package:itantra_voice_transceiver/models/message_model.dart';
import 'package:itantra_voice_transceiver/providers/communication_provider.dart';
import 'package:itantra_voice_transceiver/providers/connection_provider.dart';
import 'package:itantra_voice_transceiver/providers/emergency_provider.dart';
import 'package:itantra_voice_transceiver/providers/language_provider.dart';
import 'package:itantra_voice_transceiver/repositories/message_repository.dart';
import 'package:itantra_voice_transceiver/services/communication/mock_communication_service.dart';
import 'package:itantra_voice_transceiver/services/stt/mock_stt_service.dart';
import 'package:itantra_voice_transceiver/services/tts/mock_tts_service.dart';

void main() {
  group('Model & Constant Tests', () {
    test('LanguageModel equality and string formatting', () {
      const lang1 = LanguageModel(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు');
      const lang2 = LanguageModel(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు');
      expect(lang1, equals(lang2));
      expect(lang1.toString(), 'Telugu (తెలుగు)');
    });

    test('Supported languages include 10 required Indian languages', () {
      final codes = AppConstants.supportedLanguages.map((l) => l.code).toSet();
      expect(codes.contains('en'), isTrue);
      expect(codes.contains('hi'), isTrue);
      expect(codes.contains('te'), isTrue);
      expect(codes.contains('ta'), isTrue);
      expect(codes.contains('kn'), isTrue);
      expect(codes.contains('ml'), isTrue);
      expect(codes.contains('mr'), isTrue);
      expect(codes.contains('gu'), isTrue);
      expect(codes.contains('bn'), isTrue);
      expect(codes.contains('or'), isTrue);
    });

    test('MessageModel creation and copyWith', () {
      final now = DateTime.now();
      final msg = MessageModel(
        id: 'test-1',
        text: 'Send the location to the rescue team.',
        sender: 'You',
        receiver: 'iTantra-Rescue-01',
        timestamp: now,
        language: 'English → Telugu',
        status: MessageStatus.sending,
      );

      expect(msg.isSentByMe, isTrue);
      final delivered = msg.copyWith(status: MessageStatus.delivered);
      expect(delivered.status, MessageStatus.delivered);
    });
  });

  group('Mock Service Tests', () {
    test('MockSttService starts, emits waveform and transcribed text', () async {
      final stt = MockSttService();
      await stt.startListening(languageCode: 'en');
      expect(stt.isListening, isTrue);

      final result = await stt.stopListening();
      expect(stt.isListening, isFalse);
      expect(result.isNotEmpty, isTrue);
      stt.dispose();
    });

    test('MockTtsService speaks and stops', () async {
      final tts = MockTtsService();
      await tts.speak('Location confirmed.', languageCode: 'en');
      expect(tts.isSpeaking, isTrue);
      await tts.stop();
      expect(tts.isSpeaking, isFalse);
      tts.dispose();
    });

    test('MockCommunicationService connects, disconnects, and sends message', () async {
      final comm = MockCommunicationService();
      expect(comm.currentStatus, ConnectionStatus.connected);

      const device = DeviceModel(
        id: 'test-device',
        name: 'iTantra-Test-01',
        connectionType: ConnectionType.wifiDirect,
        signalStrength: 0.9,
      );

      await comm.connect(device);
      expect(comm.connectedDevice?.name, 'iTantra-Test-01');

      final msg = MessageModel(
        id: 'msg-1',
        text: 'Test packet',
        sender: 'You',
        receiver: 'iTantra-Test-01',
        timestamp: DateTime.now(),
        language: 'English → Telugu',
        status: MessageStatus.sending,
      );

      await comm.sendMessage(msg);

      await comm.disconnect();
      expect(comm.currentStatus, ConnectionStatus.disconnected);
      comm.dispose();
    });
  });

  group('Communication & Emergency State Transition Tests', () {
    test('Communication state transitions from Idle -> Listening -> Processing -> MessageReady -> Sending -> Sent', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(communicationProvider.notifier);
      expect(container.read(communicationProvider).isIdle, isTrue);

      // Start listening
      await notifier.startListening();
      expect(container.read(communicationProvider).isListening, isTrue);

      // Stop listening and process
      await notifier.stopListeningAndProcess();
      expect(container.read(communicationProvider).isMessageReady, isTrue);
      expect(container.read(communicationProvider).currentText.isNotEmpty, isTrue);

      // Send message
      await notifier.sendMessage();
      expect(container.read(communicationProvider).isSent, isTrue);

      // Reset to idle
      notifier.resetToIdle();
      expect(container.read(communicationProvider).isIdle, isTrue);
    });

    test('Emergency state transitions from Idle -> Confirming -> Sending -> Sent -> Received', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(emergencyProvider.notifier);
      expect(container.read(emergencyProvider).state, EmergencyState.idle);

      // Arm / Confirming
      notifier.arm('Medical emergency. Immediate assistance required.');
      expect(container.read(emergencyProvider).isConfirming, isTrue);

      // Confirm & Send
      await notifier.confirmAndSend();
      expect(container.read(emergencyProvider).isSent, isTrue);

      // Simulate receiving
      notifier.simulateReceiveEmergency(
        text: 'Rescue team en route to grid.',
        sender: 'iTantra-Rescue-01',
      );
      expect(container.read(emergencyProvider).isReceived, isTrue);

      // Acknowledge
      notifier.acknowledge();
      expect(container.read(emergencyProvider).state, EmergencyState.idle);
    });

    test('LanguageNotifier switches and swaps language pairs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(languageProvider.notifier);
      expect(container.read(languageProvider).pairLabel, 'English → Telugu');

      notifier.swapLanguages();
      expect(container.read(languageProvider).pairLabel, 'Telugu → English');
    });

    test('ConnectionNotifier scans and connects device', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(connectionProvider.notifier);
      await notifier.scanDevices();
      expect(container.read(connectionProvider).discoveredDevices.isNotEmpty, isTrue);

      final device = container.read(connectionProvider).discoveredDevices.first;
      await notifier.connect(device);
      expect(container.read(connectionProvider).isConnected, isTrue);
    });
  });

  group('MessageRepository Tests', () {
    test('Repository initializes with seed history and filters correctly', () {
      final repo = MessageRepository();
      expect(repo.getAll().isNotEmpty, isTrue);

      final sentMessages = repo.getFiltered(MessageFilter.sent);
      for (final m in sentMessages) {
        expect(m.isSentByMe, isTrue);
      }

      final emergencyMessages = repo.getFiltered(MessageFilter.emergency);
      for (final m in emergencyMessages) {
        expect(m.isEmergency, isTrue);
      }

      repo.dispose();
    });
  });
}
