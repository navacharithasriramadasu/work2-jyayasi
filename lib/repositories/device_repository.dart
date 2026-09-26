import 'dart:async';
import '../models/device_model.dart';
import '../services/device/device_discovery_service.dart';

/// Repository managing radio device pairings and discovery.
class DeviceRepository {
  final DeviceDiscoveryService discoveryService;

  DeviceModel? _connectedDevice = const DeviceModel(
    id: 'device-rescue-01',
    name: 'iTantra-Rescue-01',
    connectionType: ConnectionType.wifiDirect,
    signalStrength: 0.95,
    isConnected: true,
  );

  final _deviceListController = StreamController<List<DeviceModel>>.broadcast();

  DeviceRepository({required this.discoveryService});

  DeviceModel? get connectedDevice => _connectedDevice;

  Future<List<DeviceModel>> scanForDevices({ConnectionType? type}) async {
    final devices = await discoveryService.discoverDevices(type: type);
    _deviceListController.add(devices);
    return devices;
  }

  void setConnectedDevice(DeviceModel? device) {
    _connectedDevice = device?.copyWith(isConnected: true);
  }

  void disconnectDevice() {
    _connectedDevice = null;
  }

  Stream<List<DeviceModel>> watchDiscoveredDevices() =>
      _deviceListController.stream;

  void dispose() {
    _deviceListController.close();
  }
}
