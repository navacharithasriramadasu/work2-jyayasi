import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/config/api_config.dart';
import '../../models/connection_model.dart';
import '../../models/device_model.dart';
import '../../models/message_model.dart';
import '../location/location_service.dart';

/// Real WebSocket Gateway Client for bidirectional real-time packet exchange.
class TransceiverWebSocketService {
  final LocationService? _locationService;
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  TransceiverWebSocketService({LocationService? locationService})
      // ignore: prefer_initializing_formals
      : _locationService = locationService;

  final _incomingMessageController = StreamController<MessageModel>.broadcast();
  final _incomingSosController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;

  ConnectionStatus get status => _status;
  Stream<MessageModel> get incomingMessages => _incomingMessageController.stream;
  Stream<Map<String, dynamic>> get incomingSosStream => _incomingSosController.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Connect to the WebSocket stream gateway
  void connect() {
    if (_isDisposed) return;
    if (_status == ConnectionStatus.connecting || _status == ConnectionStatus.connected) return;

    _setStatus(ConnectionStatus.connecting);

    try {
      final uri = Uri.parse(ApiConfig.wsUrl);
      dev.log('[WebSocketService] Connecting to ${ApiConfig.wsUrl}');

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          _handleIncomingData(data);
        },
        onDone: () {
          dev.log('[WebSocketService] Connection closed');
          _setStatus(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
        onError: (error) {
          dev.log('[WebSocketService] Connection error: $error');
          _setStatus(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _setStatus(ConnectionStatus.connected);
      _startHeartbeat();
      subscribeToChannel(ApiConfig.activeChannelId);
    } catch (e) {
      dev.log('[WebSocketService] Exception during connect: $e');
      _setStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _setStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_status == ConnectionStatus.connected) {
        sendFrame('HEARTBEAT', {
          'batteryPct': 88.0,
          'rssiDbm': -64.0,
        });
      }
    });
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed && _status == ConnectionStatus.disconnected) {
        dev.log('[WebSocketService] Attempting automatic reconnect...');
        connect();
      }
    });
  }

  /// Subscribe socket to specific tactical channel
  void subscribeToChannel(String channelId) {
    sendFrame('SUBSCRIBE', {
      'channelId': channelId,
    });
  }

  /// Send generic JSON envelope
  void sendFrame(String event, Map<String, dynamic> data) {
    if (_channel == null || _status != ConnectionStatus.connected) return;

    final frame = {
      'event': event,
      'callsign': ApiConfig.callsign,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };

    try {
      _channel!.sink.add(jsonEncode(frame));
    } catch (e) {
      dev.log('[WebSocketService] Failed to send frame $event: $e');
    }
  }

  /// Send compact-text packet over WebSocket
  void sendPacket(MessageModel message) {
    sendFrame('INGEST_PACKET', {
      'packetId': message.id,
      'channelId': ApiConfig.activeChannelId,
      'sourceLanguage': 'en',
      'targetLanguage': 'te',
      'compactTextPayload': message.text,
      'priority': message.isEmergency ? 'PRIORITY_EMERGENCY_SOS' : 'PRIORITY_ROUTINE',
      'latitude': _locationService?.latitude ?? 17.3850,
      'longitude': _locationService?.longitude ?? 78.4867,
    });
  }

  /// Send emergency SOS alert over WebSocket
  void sendSos(MessageModel message) {
    sendFrame('CRITICAL_SOS', {
      'packetId': message.id,
      'channelId': ApiConfig.activeChannelId,
      'compactTextPayload': message.text,
      'priority': 'PRIORITY_EMERGENCY_SOS',
      'latitude': _locationService?.latitude ?? 17.3850,
      'longitude': _locationService?.longitude ?? 78.4867,
    });
  }

  void _handleIncomingData(dynamic rawData) {
    try {
      final json = jsonDecode(rawData.toString()) as Map<String, dynamic>;
      final event = json['event'] as String? ?? '';
      final senderCallsign = json['callsign'] as String? ?? 'REMOTE';
      final data = (json['data'] as Map<String, dynamic>?) ?? {};

      switch (event) {
        case 'INGEST_PACKET_RECEIVED':
          final payload = data['compactTextPayload'] as String? ?? '';
          final packetId = data['packetId'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
          final isEmergency = data['priority'] == 'PRIORITY_EMERGENCY_SOS';

          final incoming = MessageModel(
            id: packetId,
            text: payload,
            sender: senderCallsign == ApiConfig.callsign ? 'You' : senderCallsign,
            receiver: 'You',
            timestamp: DateTime.now(),
            language: 'Tactical Stream',
            status: MessageStatus.received,
            isEmergency: isEmergency,
            connectionType: ConnectionType.wifiDirect,
          );

          _incomingMessageController.add(incoming);
          break;

        case 'CRITICAL_SOS_TRIGGERED':
          _incomingSosController.add({
            'incidentId': data['incidentId'] ?? '',
            'callsign': senderCallsign,
            'packetId': data['packetId'] ?? '',
            'alertType': data['alertType'] ?? 'CRITICAL_SOS_BROADCAST',
          });
          break;

        case 'HEARTBEAT_ACK':
          dev.log('[WebSocketService] Heartbeat acknowledged by server');
          break;

        default:
          dev.log('[WebSocketService] Received unhandled event: $event');
          break;
      }
    } catch (e) {
      dev.log('[WebSocketService] Error parsing incoming data: $e');
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _incomingMessageController.close();
    _incomingSosController.close();
    _statusController.close();
  }
}
