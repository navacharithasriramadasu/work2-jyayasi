// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:developer' as dev;
import '../../core/config/api_config.dart';
import '../../models/connection_model.dart';
import '../../models/device_model.dart';
import '../../models/message_model.dart';
import '../api/api_service.dart';
import '../websocket/transceiver_websocket_service.dart';
import 'communication_service.dart';

/// Real Production Communication Transport integrating REST API and WebSocket Gateway.
/// Manages compact-text transmission, real-time message stream, and offline backlog sync.
class BackendCommunicationService implements CommunicationService {
  final ApiService _apiService;
  final TransceiverWebSocketService _wsService;

  final _incomingController = StreamController<MessageModel>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  final List<MessageModel> _offlineBacklog = [];
  StreamSubscription? _wsMessageSub;
  StreamSubscription? _wsStatusSub;

  DeviceModel? _connectedDevice;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  BackendCommunicationService({
    required ApiService apiService,
    required TransceiverWebSocketService wsService,
  })  : _apiService = apiService,
        _wsService = wsService {
    _init();
  }

  void _init() {
    _wsMessageSub = _wsService.incomingMessages.listen((msg) {
      _incomingController.add(msg);
    });

    _wsStatusSub = _wsService.statusStream.listen((status) {
      _status = status;
      _statusController.add(_status);
      if (status == ConnectionStatus.connected) {
        _flushOfflineBacklog();
      }
    });

    // Auto-connect to gateway on startup
    _connectInitial();
  }

  Future<void> _connectInitial() async {
    _status = ConnectionStatus.connecting;
    _statusController.add(_status);

    final isHealthy = await _apiService.checkHealth();
    if (isHealthy) {
      _wsService.connect();
      _connectedDevice = DeviceModel(
        id: ApiConfig.activeChannelId,
        name: 'COMMAND_NET (434.25 MHz)',
        connectionType: ConnectionType.wifiDirect,
        signalStrength: 0.95,
        isConnected: true,
      );
      _status = ConnectionStatus.connected;
      _statusController.add(_status);
    } else {
      _status = ConnectionStatus.disconnected;
      _statusController.add(_status);
    }
  }

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

    ApiConfig.activeChannelId = device.id;
    _wsService.connect();
    _wsService.subscribeToChannel(device.id);

    _connectedDevice = device.copyWith(isConnected: true);
    _status = ConnectionStatus.connected;
    _statusController.add(_status);
  }

  @override
  Future<void> disconnect() async {
    _wsService.disconnect();
    _connectedDevice = null;
    _status = ConnectionStatus.disconnected;
    _statusController.add(_status);
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    // 1. Send via low-latency WebSocket if active
    if (_wsService.status == ConnectionStatus.connected) {
      _wsService.sendPacket(message);
    }

    // 2. Transmit via REST API ingest
    final success = await _apiService.sendIngestPacket(message);

    if (!success) {
      // Offline fallback: Buffer to backlog
      dev.log('[BackendComm] Link unavailable or rejected, queuing for sync: ${message.id}');
      _offlineBacklog.add(message);
    }
  }

  /// Flushes offline queue to backend using batch sync endpoint
  Future<void> _flushOfflineBacklog() async {
    if (_offlineBacklog.isEmpty) return;

    dev.log('[BackendComm] Flushing ${_offlineBacklog.length} queued offline packets...');
    final packetsToSync = List<MessageModel>.from(_offlineBacklog);
    final success = await _apiService.syncBatchPackets(packetsToSync);

    if (success) {
      _offlineBacklog.clear();
      dev.log('[BackendComm] Offline backlog successfully synced to C2 portal.');
    }
  }

  void dispose() {
    _wsMessageSub?.cancel();
    _wsStatusSub?.cancel();
    _incomingController.close();
    _statusController.close();
  }
}
