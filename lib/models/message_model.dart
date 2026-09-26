import 'device_model.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  received,
  heard,
  failed,
}

extension MessageStatusExtension on MessageStatus {
  String get label {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.received:
        return 'Received';
      case MessageStatus.heard:
        return 'Heard';
      case MessageStatus.failed:
        return 'Failed';
    }
  }
}

/// Represents a transmitted or received text payload in iTantra.
/// "Voice communication without transmitting voice."
class MessageModel {
  final String id;
  final String text;
  final String sender; // 'You' or remote device name
  final String receiver; // Remote device name or 'You'
  final DateTime timestamp;
  final String language; // e.g. 'English -> Telugu'
  final MessageStatus status;
  final bool isEmergency;
  final ConnectionType connectionType;
  final String? translatedText;

  const MessageModel({
    required this.id,
    required this.text,
    required this.sender,
    required this.receiver,
    required this.timestamp,
    required this.language,
    required this.status,
    this.isEmergency = false,
    this.connectionType = ConnectionType.wifiDirect,
    this.translatedText,
  });

  bool get isSentByMe => sender == 'You';

  MessageModel copyWith({
    String? id,
    String? text,
    String? sender,
    String? receiver,
    DateTime? timestamp,
    String? language,
    MessageStatus? status,
    bool? isEmergency,
    ConnectionType? connectionType,
    String? translatedText,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      timestamp: timestamp ?? this.timestamp,
      language: language ?? this.language,
      status: status ?? this.status,
      isEmergency: isEmergency ?? this.isEmergency,
      connectionType: connectionType ?? this.connectionType,
      translatedText: translatedText ?? this.translatedText,
    );
  }
}
