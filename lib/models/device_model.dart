enum ConnectionType {
  wifiDirect,
  bluetooth,
}

extension ConnectionTypeExtension on ConnectionType {
  String get label {
    switch (this) {
      case ConnectionType.wifiDirect:
        return 'Wi-Fi Direct';
      case ConnectionType.bluetooth:
        return 'Bluetooth';
    }
  }
}

/// Representation of a nearby or connected iTantra transceiver node.
class DeviceModel {
  final String id;
  final String name;
  final ConnectionType connectionType;
  final double signalStrength; // 0.0 to 1.0
  final bool isConnected;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.connectionType,
    this.signalStrength = 0.8,
    this.isConnected = false,
  });

  DeviceModel copyWith({
    String? id,
    String? name,
    ConnectionType? connectionType,
    double? signalStrength,
    bool? isConnected,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      signalStrength: signalStrength ?? this.signalStrength,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
