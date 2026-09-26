import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../models/device_model.dart';
import '../../models/message_model.dart';
import 'mock_communication_service.dart';
import '../tts/tts_service.dart';

/// Orchestrates realistic two-way transceiver demonstration.
/// Allows a complete live showcase of:
/// Sender -> Local STT -> Text Transmit -> Receiver Received -> Local TTS Announcement.
class DemoSimulationService {
  final MockCommunicationService communicationService;
  final TtsService ttsService;
  static const _uuid = Uuid();

  DemoSimulationService({
    required this.communicationService,
    required this.ttsService,
  });

  /// Trigger a simulated incoming response from the remote rescue device
  /// after a short delay (e.g. 3.5 seconds after user sends message).
  void scheduleSimulatedRemoteResponse({
    required String promptResponse,
    required String senderName,
    required String languagePair,
    bool isEmergency = false,
  }) {
    Timer(const Duration(milliseconds: 3200), () {
      final incomingMessage = MessageModel(
        id: _uuid.v4(),
        text: promptResponse,
        sender: senderName,
        receiver: 'You',
        timestamp: DateTime.now(),
        language: languagePair,
        status: MessageStatus.received,
        isEmergency: isEmergency,
        connectionType: ConnectionType.wifiDirect,
      );

      // Inject into incoming pipeline
      communicationService.simulateIncomingMessage(incomingMessage);
    });
  }
}
