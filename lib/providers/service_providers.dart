import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/device_repository.dart';
import '../repositories/message_repository.dart';
import '../services/api/api_service.dart';
import '../services/communication/backend_communication_service.dart';
import '../services/communication/communication_service.dart';
import '../services/device/backend_device_discovery_service.dart';
import '../services/device/device_discovery_service.dart';
import '../services/location/location_service.dart';
import '../services/settings/device_settings_service.dart';
import '../services/stt/device_stt_service.dart';
import '../services/stt/stt_service.dart';
import '../services/tts/device_tts_service.dart';
import '../services/tts/tts_service.dart';
import '../services/websocket/transceiver_websocket_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  service.updateCurrentLocation();
  return service;
});

final deviceSettingsServiceProvider = Provider<DeviceSettingsService>((ref) {
  final service = DeviceSettingsService();
  service.init();
  return service;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final location = ref.watch(locationServiceProvider);
  final service = ApiService(locationService: location);
  ref.onDispose(() => service.dispose());
  return service;
});

final webSocketServiceProvider = Provider<TransceiverWebSocketService>((ref) {
  final location = ref.watch(locationServiceProvider);
  final service = TransceiverWebSocketService(locationService: location);
  ref.onDispose(() => service.dispose());
  return service;
});

final sttServiceProvider = Provider<SttService>((ref) {
  final service = DeviceSttService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = DeviceTtsService();
  ref.onDispose(() => service.dispose());
  return service;
});

final communicationServiceProvider = Provider<CommunicationService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final ws = ref.watch(webSocketServiceProvider);
  final service = BackendCommunicationService(
    apiService: api,
    wsService: ws,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final deviceDiscoveryServiceProvider = Provider<DeviceDiscoveryService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final service = BackendDeviceDiscoveryService(apiService: api);
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
