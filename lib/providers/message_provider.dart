import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../repositories/message_repository.dart';
import 'service_providers.dart';

class MessageFilterNotifier extends Notifier<MessageFilter> {
  @override
  MessageFilter build() => MessageFilter.all;

  void setFilter(MessageFilter filter) {
    state = filter;
  }
}

final messageFilterProvider =
    NotifierProvider<MessageFilterNotifier, MessageFilter>(
  MessageFilterNotifier.new,
);

class MessageListNotifier extends Notifier<List<MessageModel>> {
  late final MessageRepository _repository;

  @override
  List<MessageModel> build() {
    _repository = ref.watch(messageRepositoryProvider);
    final sub = _repository.watchMessages().listen((messages) {
      state = messages;
    });
    ref.onDispose(sub.cancel);
    return _repository.getAll();
  }

  void addMessage(MessageModel message) {
    _repository.addMessage(message);
  }

  void updateStatus(String id, MessageStatus status) {
    _repository.updateStatus(id, status);
  }
}

final messageListProvider =
    NotifierProvider<MessageListNotifier, List<MessageModel>>(
  MessageListNotifier.new,
);

final filteredMessagesProvider = Provider<List<MessageModel>>((ref) {
  final filter = ref.watch(messageFilterProvider);
  final repo = ref.watch(messageRepositoryProvider);
  ref.watch(messageListProvider); // Re-run when list changes
  return repo.getFiltered(filter);
});

final latestMessageProvider = Provider<MessageModel?>((ref) {
  final list = ref.watch(messageListProvider);
  return list.isNotEmpty ? list.first : null;
});
