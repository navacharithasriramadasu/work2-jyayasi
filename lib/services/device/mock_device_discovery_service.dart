import 'dart:async';
import '../../models/device_model.dart';
import 'device_discovery_service.dart';

/// Mock implementation of DeviceDiscoveryService for Wi-Fi Direct and Bluetooth.
class MockDeviceDiscoveryService implements DeviceDiscoveryService {
  final _deviceStreamController = StreamController<List<DeviceModel>>.broadcast();

  final List<DeviceModel> _mockDevices = const [
    DeviceModel(
      id: 'device-rescue-01',
      name: 'iTantra-Rescue-01',
      connectionType: ConnectionType.wifiDirect,
      signalStrength: 0.95,
      isConnected: true,
    ),
    DeviceModel(
      id: 'device-field-02',
      name: 'iTantra-Field-02',
      connectionType: ConnectionType.wifiDirect,
      signalStrength: 0.65,
      isConnected: false,
    ),
    DeviceModel(
      id: 'device-base-03',
      name: 'iTantra-Base-03',
      connectionType: ConnectionType.bluetooth,
      signalStrength: 0.35,
      isConnected: false,
    ),
    DeviceModel(
      id: 'device-command-04',
      name: 'iTantra-Command-04',
      connectionType: ConnectionType.bluetooth,
      signalStrength: 0.55,
      isConnected: false,
    ),
  ];

  @override
  Stream<List<DeviceModel>> get discoveredDevicesStream =>
      _deviceStreamController.stream;

  @override
  Future<List<DeviceModel>> discoverDevices({ConnectionType? type}) async {
    // Simulate radio discovery scan latency (600ms)
    await Future.delayed(const Duration(milliseconds: 600));

    final filtered = type == null
        ? _mockDevices
        : _mockDevices.where((d) => d.connectionType == type).toList();

    _deviceStreamController.add(filtered);
    return filtered;
  }

  @override
  Future<void> stopDiscovery() async {
    // No-op for mock
  }

  void dispose() {
    _deviceStreamController.close();
  }
}
