import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';

/// Dynamic settings persistence service using SharedPreferences.
class DeviceSettingsService {
  static const String _keyCallsign = 'itantra_callsign';
  static const String _keyDeviceId = 'itantra_device_id';
  static const String _keyEnv = 'itantra_api_env';
  static const String _keyCustomHost = 'itantra_custom_host';
  static const String _keyCustomPort = 'itantra_custom_port';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final callsign = _prefs?.getString(_keyCallsign);
    if (callsign != null && callsign.isNotEmpty) {
      ApiConfig.callsign = callsign;
    }

    final devId = _prefs?.getString(_keyDeviceId);
    if (devId != null && devId.isNotEmpty) {
      ApiConfig.deviceId = devId;
    }

    final envIndex = _prefs?.getInt(_keyEnv);
    if (envIndex != null && envIndex >= 0 && envIndex < BackendEnvironment.values.length) {
      ApiConfig.environment = BackendEnvironment.values[envIndex];
    }

    final customHost = _prefs?.getString(_keyCustomHost);
    if (customHost != null && customHost.isNotEmpty) {
      ApiConfig.customHost = customHost;
    }

    final customPort = _prefs?.getInt(_keyCustomPort);
    if (customPort != null) {
      ApiConfig.customPort = customPort;
    }
  }

  Future<void> setCallsign(String callsign) async {
    ApiConfig.callsign = callsign;
    await _prefs?.setString(_keyCallsign, callsign);
  }

  Future<void> setDeviceId(String deviceId) async {
    ApiConfig.deviceId = deviceId;
    await _prefs?.setString(_keyDeviceId, deviceId);
  }

  Future<void> setEnvironment(BackendEnvironment env, {String? customHost, int? customPort}) async {
    ApiConfig.environment = env;
    await _prefs?.setInt(_keyEnv, env.index);

    if (customHost != null) {
      ApiConfig.customHost = customHost;
      await _prefs?.setString(_keyCustomHost, customHost);
    }
    if (customPort != null) {
      ApiConfig.customPort = customPort;
      await _prefs?.setInt(_keyCustomPort, customPort);
    }
  }
}
