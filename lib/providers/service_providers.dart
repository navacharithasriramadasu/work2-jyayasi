import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/device_repository.dart';
import '../repositories/message_repository.dart';
import '../services/communication/communication_service.dart';
import '../services/communication/demo_simulation_service.dart';
import '../services/communication/mock_communication_service.dart';
import '../services/device/device_discovery_service.dart';
import '../services/device/mock_device_discovery_service.dart';
import '../services/stt/mock_stt_service.dart';
import '../services/stt/stt_service.dart';
import '../services/tts/mock_tts_service.dart';
import '../services/tts/tts_service.dart';

final sttServiceProvider = Provider<SttService>((ref) {
  final service = MockSttService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = MockTtsService();
  ref.onDispose(() => service.dispose());
  return service;
});

final communicationServiceProvider = Provider<CommunicationService>((ref) {
  final service = MockCommunicationService();
  ref.onDispose(() => service.dispose());
  return service;
});

final deviceDiscoveryServiceProvider = Provider<DeviceDiscoveryService>((ref) {
  final service = MockDeviceDiscoveryService();
  ref.onDispose(() => service.dispose());
  return service;
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final repo = MessageRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final discovery = ref.watch(deviceDiscoveryServiceProvider);
  final repo = DeviceRepository(discoveryService: discovery);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final demoSimulationServiceProvider = Provider<DemoSimulationService>((ref) {
  final commService = ref.watch(communicationServiceProvider) as MockCommunicationService;
  final ttsService = ref.watch(ttsServiceProvider);
  return DemoSimulationService(
    communicationService: commService,
    ttsService: ttsService,
  );
});
