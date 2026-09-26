import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/communication_provider.dart';
import '../../providers/message_provider.dart';
import '../../repositories/message_repository.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/message_card.dart';

/// Technical communication log with tabbed category filters.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(messageFilterProvider);
    final messages = ref.watch(filteredMessagesProvider);

    return AppScaffold(
      title: 'Communication History',
      body: Column(
        children: [
          // Filter Tabs (All, Sent, Received, Emergency)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildFilterChip(
                  context: context,
                  ref: ref,
                  label: 'All',
                  filter: MessageFilter.all,
                  isSelected: currentFilter == MessageFilter.all,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  ref: ref,
                  label: 'Sent',
                  filter: MessageFilter.sent,
                  isSelected: currentFilter == MessageFilter.sent,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  ref: ref,
                  label: 'Received',
                  filter: MessageFilter.received,
                  isSelected: currentFilter == MessageFilter.received,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  ref: ref,
                  label: 'Emergency',
                  filter: MessageFilter.emergency,
                  isSelected: currentFilter == MessageFilter.emergency,
                  isEmergency: true,
                ),
              ],
            ),
          ),

          // Message Log List
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox,
                          size: 40,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transmissions found in this category',
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return MessageCard(
                        message: message,
                        onReplay: !message.isSentByMe
                            ? () {
                                ref
                                    .read(communicationProvider.notifier)
                                    .speakIncomingMessage(message.text);
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required MessageFilter filter,
    required bool isSelected,
    bool isEmergency = false,
  }) {
    Color activeColor =
        isEmergency ? AppColors.emergency : AppColors.primaryAccent;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(messageFilterProvider.notifier).setFilter(filter);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.16)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.supporting.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isSelected ? activeColor : AppColors.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
