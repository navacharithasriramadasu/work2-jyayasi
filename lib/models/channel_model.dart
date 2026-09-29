class ChannelModel {
  final String channelId;
  final String name;
  final String description;
  final double frequencyMhz;
  final bool isEncrypted;
  final int activeSubscribers;

  const ChannelModel({
    required this.channelId,
    required this.name,
    required this.description,
    required this.frequencyMhz,
    this.isEncrypted = false,
    this.activeSubscribers = 0,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      channelId: json['channelId'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['channelName'] as String? ?? 'Tactical Net',
      description: json['description'] as String? ?? '',
      frequencyMhz: (json['frequencyMhz'] as num?)?.toDouble() ?? 433.92,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      activeSubscribers: (json['activeSubscribers'] as num?)?.toInt() ??
          (json['activeMembers'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'name': name,
        'description': description,
        'frequencyMhz': frequencyMhz,
        'isEncrypted': isEncrypted,
        'activeSubscribers': activeSubscribers,
      };
}
