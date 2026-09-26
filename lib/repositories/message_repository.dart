import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/device_model.dart';
import '../models/message_model.dart';

enum MessageFilter {
  all,
  sent,
  received,
  emergency,
}

/// In-memory repository managing communication history for iTantra.
class MessageRepository {
  final _uuid = const Uuid();
  final _messages = <MessageModel>[];
  final _streamController = StreamController<List<MessageModel>>.broadcast();

  MessageRepository() {
    _seedInitialHistory();
  }

  void _seedInitialHistory() {
    final now = DateTime.now();
    _messages.addAll([
      MessageModel(
        id: _uuid.v4(),
        text: 'Medical assistance required.',
        sender: 'iTantra-Rescue-01',
        receiver: 'You',
        timestamp: now.subtract(const Duration(minutes: 28)),
        language: 'Telugu → English',
        status: MessageStatus.heard,
        isEmergency: true,
        connectionType: ConnectionType.wifiDirect,
      ),
      MessageModel(
        id: _uuid.v4(),
        text: 'Location coordinates received. Unit moving to sector.',
        sender: 'iTantra-Rescue-01',
        receiver: 'You',
        timestamp: now.subtract(const Duration(minutes: 47)),
        language: 'Telugu → English',
        status: MessageStatus.heard,
        isEmergency: false,
        connectionType: ConnectionType.wifiDirect,
      ),
      MessageModel(
        id: _uuid.v4(),
        text: 'Send the location to the rescue team.',
        sender: 'You',
        receiver: 'iTantra-Rescue-01',
        timestamp: now.subtract(const Duration(minutes: 48)),
        language: 'English → Telugu',
        status: MessageStatus.delivered,
        isEmergency: false,
        connectionType: ConnectionType.wifiDirect,
      ),
    ]);
    _emit();
  }

  List<MessageModel> getAll() => List.unmodifiable(_messages);

  List<MessageModel> getFiltered(MessageFilter filter) {
    switch (filter) {
      case MessageFilter.all:
        return getAll();
      case MessageFilter.sent:
        return _messages.where((m) => m.isSentByMe).toList();
      case MessageFilter.received:
        return _messages.where((m) => !m.isSentByMe).toList();
      case MessageFilter.emergency:
        return _messages.where((m) => m.isEmergency).toList();
    }
  }

  Stream<List<MessageModel>> watchMessages() => _streamController.stream;

  MessageModel? get latestMessage => _messages.isNotEmpty ? _messages.first : null;

  void addMessage(MessageModel message) {
    _messages.insert(0, message);
    _emit();
  }

  void updateStatus(String id, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
      _emit();
    }
  }

  void _emit() {
    _streamController.add(List.unmodifiable(_messages));
  }

  void dispose() {
    _streamController.close();
  }
}
