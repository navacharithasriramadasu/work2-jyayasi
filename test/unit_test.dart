import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itantra_voice_transceiver/core/constants/app_constants.dart';
import 'package:itantra_voice_transceiver/models/connection_model.dart';
import 'package:itantra_voice_transceiver/models/device_model.dart';
import 'package:itantra_voice_transceiver/models/language_model.dart';
import 'package:itantra_voice_transceiver/models/message_model.dart';
import 'package:itantra_voice_transceiver/providers/emergency_provider.dart';
import 'package:itantra_voice_transceiver/providers/language_provider.dart';
import 'package:itantra_voice_transceiver/repositories/message_repository.dart';

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

    test('DeviceModel connectionType label is correct', () {
      const device = DeviceModel(
        id: 'dev-001',
        name: 'iTantra-Rescue-01',
        connectionType: ConnectionType.wifiDirect,
        signalStrength: 0.85,
      );
      // The extension on ConnectionType provides a label getter
      expect(device.connectionType.label, 'Wi-Fi Direct');
      expect(device.signalStrength, greaterThan(0.5));
    });
  });

  group('Emergency State Transition Tests', () {
    test('Emergency state transitions from Idle -> Confirming -> Sent -> Received -> Idle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(emergencyProvider.notifier);
      expect(container.read(emergencyProvider).state, EmergencyState.idle);

      // Arm
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
  });

  group('Language Provider Tests', () {
    test('LanguageNotifier switches and swaps language pairs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(languageProvider.notifier);
      expect(container.read(languageProvider).pairLabel, 'English → Telugu');

      notifier.swapLanguages();
      expect(container.read(languageProvider).pairLabel, 'Telugu → English');
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
