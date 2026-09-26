import 'dart:async';
import '../../models/connection_model.dart';
import '../../models/device_model.dart';
import '../../models/message_model.dart';
import 'communication_service.dart';

/// Mock Wi-Fi Direct and Bluetooth communication transport.
/// Simulates packet transmission over radio link (TEXT ONLY, NO AUDIO).
class MockCommunicationService implements CommunicationService {
  final _incomingController = StreamController<MessageModel>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  DeviceModel? _connectedDevice = const DeviceModel(
    id: 'device-rescue-01',
    name: 'iTantra-Rescue-01',
    connectionType: ConnectionType.wifiDirect,
    signalStrength: 0.95,
    isConnected: true,
  );

  ConnectionStatus _status = ConnectionStatus.connected;

  @override
  DeviceModel? get connectedDevice => _connectedDevice;

  @override
  ConnectionStatus get currentStatus => _status;

  @override
  Stream<MessageModel> get incomingMessages => _incomingController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;

  @override
  Future<void> connect(DeviceModel device) async {
    _status = ConnectionStatus.connecting;
    _statusController.add(_status);

    await Future.delayed(const Duration(milliseconds: 700));

    _connectedDevice = device.copyWith(isConnected: true);
    _status = ConnectionStatus.connected;
    _statusController.add(_status);
  }

  @override
  Future<void> disconnect() async {
    _status = ConnectionStatus.disconnected;
    _connectedDevice = null;
    _statusController.add(_status);
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    // Simulate low-bandwidth text transmission latency (400ms)
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Inject an incoming message (used by demo simulator or external events)
  void simulateIncomingMessage(MessageModel message) {
    _incomingController.add(message);
  }

  void dispose() {
    _incomingController.close();
    _statusController.close();
  }
}
