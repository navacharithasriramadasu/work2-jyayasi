class ActiveIncidentModel {
  final String incidentId;
  final String packetId;
  final String initiatingCallsign;
  final String alertType;
  final String status;
  final String? firstResponderAssigned;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const ActiveIncidentModel({
    required this.incidentId,
    required this.packetId,
    required this.initiatingCallsign,
    required this.alertType,
    required this.status,
    this.firstResponderAssigned,
    this.createdAt,
    this.resolvedAt,
  });

  factory ActiveIncidentModel.fromJson(Map<String, dynamic> json) {
    return ActiveIncidentModel(
      incidentId: json['incidentId'] as String? ?? '',
      packetId: json['packetId'] as String? ?? '',
      initiatingCallsign: json['initiatingCallsign'] as String? ?? 'UNKNOWN',
      alertType: json['alertType'] as String? ?? 'CRITICAL_SOS_BROADCAST',
      status: json['status'] as String? ?? 'ACTIVE_DISPATCH',
      firstResponderAssigned: json['firstResponderAssigned'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'incidentId': incidentId,
        'packetId': packetId,
        'initiatingCallsign': initiatingCallsign,
        'alertType': alertType,
        'status': status,
        'firstResponderAssigned': firstResponderAssigned,
        'createdAt': createdAt?.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };
}
