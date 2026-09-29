enum BackendEnvironment {
  production,
  emulator,
  lan,
  fieldEdge,
  customDomain,
}

/// Centralized configuration for iTantra Backend APIs & Real-Time Gateway.
class ApiConfig {
  ApiConfig._();

  static BackendEnvironment currentEnvironment = BackendEnvironment.production;

  // Active callsign representing this handset node
  static String callsign = 'ALPHA-1';

  // Device identifier
  static String deviceId = 'dev-alpha-001-node';

  // Configurable session / Bearer token (if authentication is required)
  static String bearerToken = 'SEC_PROD_99a8b2d18471c2948e9104b281f9a8471b0284e7a2b91c84';

  // Currently active channel ID (defaulting to Command Net)
  static String activeChannelId = 'chan-cmd-net-02';

  // Local workstation LAN IP when testing on physical handset
  static String lanHostIp = '192.168.1.100';

  // Custom host and port
  static String customHost = '192.168.1.100';
  static int customPort = 3000;

  static BackendEnvironment get environment => currentEnvironment;
  static set environment(BackendEnvironment env) => currentEnvironment = env;

  static String get baseUrl {
    switch (currentEnvironment) {
      case BackendEnvironment.production:
        return 'https://itantra-c2-portal.onrender.com';
      case BackendEnvironment.emulator:
        return 'http://10.0.2.2:3000';
      case BackendEnvironment.lan:
        return 'http://$lanHostIp:3000';
      case BackendEnvironment.fieldEdge:
        return 'http://192.168.10.1:3000';
      case BackendEnvironment.customDomain:
        return 'https://c2.itantra.org';
    }
  }

  static String get wsUrl {
    switch (currentEnvironment) {
      case BackendEnvironment.production:
        return 'wss://itantra-stream-gateway.onrender.com/v1/transceiver/channel';
      case BackendEnvironment.emulator:
        return 'ws://10.0.2.2:8443/v1/transceiver/channel';
      case BackendEnvironment.lan:
        return 'ws://$lanHostIp:8443/v1/transceiver/channel';
      case BackendEnvironment.fieldEdge:
        return 'ws://192.168.10.1:8443/v1/transceiver/channel';
      case BackendEnvironment.customDomain:
        return 'wss://stream.itantra.org/v1/transceiver/channel';
    }
  }

  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        'x-transceiver-callsign': callsign,
        if (bearerToken.isNotEmpty) 'Authorization': 'Bearer $bearerToken',
      };
}
