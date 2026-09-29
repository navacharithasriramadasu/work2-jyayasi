// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../models/channel_model.dart';

import '../../models/device_model.dart';
import '../../models/incident_model.dart';
import '../../models/message_model.dart';
import '../location/location_service.dart';

/// Real REST API client for iTantra C2 Backend Gateway.
class ApiService {
  final http.Client _client;
  final LocationService? _locationService;

  ApiService({http.Client? client, LocationService? locationService})
      : _client = client ?? http.Client(),
        _locationService = locationService;

  /// GET /api/healthz - Check backend availability
  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/healthz');
      final res = await _client.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['status'] == 'HEALTHY';
      }
      return false;
    } catch (e) {
      dev.log('[ApiService] Health check error: $e');
      return false;
    }
  }

  /// GET /api/v1/channels - Retrieve tactical radio channels
  Future<List<ChannelModel>> fetchChannels() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/channels');
      final res = await _client.get(url, headers: ApiConfig.authHeaders).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['channels'] is List) {
          final list = (data['channels'] as List)
              .map((c) => ChannelModel.fromJson(c as Map<String, dynamic>))
              .toList();
          return list;
        }
      }
      return [];
    } catch (e) {
      dev.log('[ApiService] fetchChannels error: $e');
      return [];
    }
  }

  /// GET /api/v1/channels/{channelId}/messages - Paginated message history
  Future<List<MessageModel>> fetchChannelMessages(
    String channelId, {
    int? since,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (since != null) 'since': since.toString(),
      };
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/channels/$channelId/messages')
          .replace(queryParameters: queryParams);

      final res = await _client.get(uri, headers: ApiConfig.authHeaders).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['messages'] is List) {
          final rawList = data['messages'] as List;
          return rawList.map((m) {
            final map = m as Map<String, dynamic>;
            final sender = map['senderCallsign'] as String? ?? 'REMOTE';
            final text = map['compactTextPayload'] as String? ?? '';
            final isEmergency = map['priority'] == 'PRIORITY_EMERGENCY_SOS';
            final packetId = map['packetId'] as String? ?? '';
            final transportStr = map['transportUsed'] as String? ?? 'WIFI_DIRECT';

            return MessageModel(
              id: packetId.isNotEmpty ? packetId : DateTime.now().microsecondsSinceEpoch.toString(),
              text: text,
              sender: sender == ApiConfig.callsign ? 'You' : sender,
              receiver: map['recipientCallsign'] as String? ?? 'All',
              timestamp: DateTime.now(),
              language: 'Tactical Mesh',
              status: MessageStatus.delivered,
              isEmergency: isEmergency,
              connectionType: transportStr.contains('BLUETOOTH')
                  ? ConnectionType.bluetooth
                  : ConnectionType.wifiDirect,
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      dev.log('[ApiService] fetchChannelMessages error: $e');
      return [];
    }
  }

  /// GET /api/v1/incidents/active - Query active emergency SOS incidents
  Future<List<ActiveIncidentModel>> fetchActiveIncidents() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/incidents/active');
      final res = await _client.get(url, headers: ApiConfig.authHeaders).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['incidents'] is List) {
          return (data['incidents'] as List)
              .map((i) => ActiveIncidentModel.fromJson(i as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      dev.log('[ApiService] fetchActiveIncidents error: $e');
      return [];
    }
  }

  /// POST /api/v1/ingest - Send single compact-text transmission
  Future<bool> sendIngestPacket(MessageModel message) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/ingest');
      final payload = {
        'packetId': message.id,
        'senderCallsign': ApiConfig.callsign,
        'recipientCallsign': message.receiver == 'You' ? 'BROADCAST_ALL' : message.receiver,
        'channelId': ApiConfig.activeChannelId,
        'compactTextPayload': message.text,
        'priority': message.isEmergency ? 'PRIORITY_EMERGENCY_SOS' : 'PRIORITY_ROUTINE',
        'transportUsed': message.connectionType == ConnectionType.bluetooth ? 'BLUETOOTH_LE' : 'WIFI_DIRECT',
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'latitude': _locationService?.latitude ?? 17.3850,
        'longitude': _locationService?.longitude ?? 78.4867,
      };

      final res = await _client
          .post(
            url,
            headers: ApiConfig.authHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log('[ApiService] sendIngestPacket error: $e');
      return false;
    }
  }

  /// POST /api/v1/sos - Emergency SOS transmission
  Future<bool> sendSos(MessageModel message) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/sos');
      final payload = {
        'packetId': message.id,
        'senderCallsign': ApiConfig.callsign,
        'recipientCallsign': 'BROADCAST_ALL',
        'channelId': ApiConfig.activeChannelId,
        'compactTextPayload': message.text,
        'priority': 'PRIORITY_EMERGENCY_SOS',
        'transportUsed': message.connectionType == ConnectionType.bluetooth ? 'BLUETOOTH_LE' : 'WIFI_DIRECT',
        'latitude': _locationService?.latitude ?? 17.3850,
        'longitude': _locationService?.longitude ?? 78.4867,
      };

      final res = await _client
          .post(
            url,
            headers: ApiConfig.authHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log('[ApiService] sendSos error: $e');
      return false;
    }
  }

  /// POST /api/v1/telemetry - Report device battery & radio health
  Future<bool> sendTelemetry({
    required double batteryPercent,
    required double signalStrengthDbm,
    String transportType = 'WIFI_DIRECT',
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/telemetry');
      final payload = {
        'callsign': ApiConfig.callsign,
        'batteryPercent': batteryPercent,
        'signalStrengthDbm': signalStrengthDbm,
        'transportType': transportType,
        'latitude': _locationService?.latitude ?? 17.3850,
        'longitude': _locationService?.longitude ?? 78.4867,
        'nodeTemperatureC': 36.5,
      };

      final res = await _client
          .post(
            url,
            headers: ApiConfig.authHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log('[ApiService] sendTelemetry error: $e');
      return false;
    }
  }

  /// POST /api/v1/transmissions/sync - Offline backlog batch sync
  Future<bool> syncBatchPackets(List<MessageModel> packets) async {
    if (packets.isEmpty) return true;
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/transmissions/sync');
      final payload = {
        'deviceId': ApiConfig.deviceId,
        'packets': packets
            .map((p) => {
                  'packetId': p.id,
                  'senderCallsign': ApiConfig.callsign,
                  'recipientCallsign': p.receiver == 'You' ? 'BROADCAST_ALL' : p.receiver,
                  'channelId': ApiConfig.activeChannelId,
                  'compactTextPayload': p.text,
                  'priority': p.isEmergency ? 'PRIORITY_EMERGENCY_SOS' : 'PRIORITY_ROUTINE',
                  'transportUsed': p.connectionType == ConnectionType.bluetooth ? 'BLUETOOTH_LE' : 'WIFI_DIRECT',
                  'timestamp': p.timestamp.millisecondsSinceEpoch,
                  'latitude': _locationService?.latitude ?? 17.3850,
                  'longitude': _locationService?.longitude ?? 78.4867,
                })
            .toList(),
      };

      final res = await _client
          .post(
            url,
            headers: ApiConfig.authHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log('[ApiService] syncBatchPackets error: $e');
      return false;
    }
  }

  /// GET /api/v1/models - Retrieve AI model manifest
  Future<List<Map<String, dynamic>>> fetchModelManifest() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/models');
      final res = await _client.get(url, headers: ApiConfig.authHeaders).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['models'] is List) {
          return List<Map<String, dynamic>>.from(data['models'] as List);
        }
      }
      return [];
    } catch (e) {
      dev.log('[ApiService] fetchModelManifest error: $e');
      return [];
    }
  }

  void dispose() {
    _client.close();
  }
}
