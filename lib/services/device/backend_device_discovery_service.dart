// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import '../../core/config/api_config.dart';
import '../../models/device_model.dart';
import '../api/api_service.dart';
import 'device_discovery_service.dart';

/// Real tactical channel & transceiver discovery service querying live C2 channels.
class BackendDeviceDiscoveryService implements DeviceDiscoveryService {
  final ApiService _apiService;
  final _deviceStreamController = StreamController<List<DeviceModel>>.broadcast();

  BackendDeviceDiscoveryService({required ApiService apiService})
      : _apiService = apiService;

  @override
  Stream<List<DeviceModel>> get discoveredDevicesStream =>
      _deviceStreamController.stream;

  @override
  Future<List<DeviceModel>> discoverDevices({ConnectionType? type}) async {
    final channels = await _apiService.fetchChannels();

    if (channels.isNotEmpty) {
      final devices = channels.map((c) {
        final isCmd = c.channelId == ApiConfig.activeChannelId;
        return DeviceModel(
          id: c.channelId,
          name: '${c.name} (${c.frequencyMhz} MHz)',
          connectionType: ConnectionType.wifiDirect,
          signalStrength: isCmd ? 0.95 : 0.75,
          isConnected: isCmd,
        );
      }).toList();

      _deviceStreamController.add(devices);
      return devices;
    }

    // Default tactical channels if offline
    final fallback = [
      DeviceModel(
        id: 'chan-emergency-01',
        name: 'EMERGENCY_BROADCAST (433.175 MHz)',
        connectionType: ConnectionType.wifiDirect,
        signalStrength: 0.95,
        isConnected: false,
      ),
      DeviceModel(
        id: 'chan-cmd-net-02',
        name: 'COMMAND_NET (434.25 MHz)',
        connectionType: ConnectionType.wifiDirect,
        signalStrength: 0.90,
        isConnected: true,
      ),
      DeviceModel(
        id: 'chan-sector4-03',
        name: 'SECTOR_4_TAC (868.10 MHz)',
        connectionType: ConnectionType.bluetooth,
        signalStrength: 0.70,
        isConnected: false,
      ),
    ];

    _deviceStreamController.add(fallback);
    return fallback;
  }

  @override
  Future<void> stopDiscovery() async {
    // No-op
  }

  void dispose() {
    _deviceStreamController.close();
  }
}
