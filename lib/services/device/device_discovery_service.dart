import '../../models/device_model.dart';

/// Abstract interface for discovering nearby Wi-Fi Direct and Bluetooth transceivers.
abstract class DeviceDiscoveryService {
  /// Scan for nearby iTantra nodes over the specified transport.
  Future<List<DeviceModel>> discoverDevices({ConnectionType? type});

  /// Stop active discovery scan.
  Future<void> stopDiscovery();

  /// Stream of newly discovered devices during scan.
  Stream<List<DeviceModel>> get discoveredDevicesStream;
}
