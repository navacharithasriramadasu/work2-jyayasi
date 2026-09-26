import '../../models/connection_model.dart';
import '../../models/device_model.dart';
import '../../models/message_model.dart';

/// Abstract communication transport interface for Wi-Fi Direct and Bluetooth.
/// Responsible for transmitting compact TEXT payloads between nodes.
/// NO raw voice/audio is ever sent over this layer.
abstract class CommunicationService {
  /// Connect to a remote iTantra node.
  Future<void> connect(DeviceModel device);

  /// Disconnect current radio link.
  Future<void> disconnect();

  /// Send a text message payload to the connected transceiver.
  Future<void> sendMessage(MessageModel message);

  /// Stream of incoming text messages received from the remote node.
  Stream<MessageModel> get incomingMessages;

  /// Stream of radio link status updates.
  Stream<ConnectionStatus> get connectionStatusStream;

  /// Currently connected device, if any.
  DeviceModel? get connectedDevice;

  /// Current radio link status.
  ConnectionStatus get currentStatus;
}
