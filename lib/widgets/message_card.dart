import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/formatters.dart';
import '../models/message_model.dart';
import 'status_chip.dart';

/// Compact technical message card for communication history and active views.
class MessageCard extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onReplay;

  const MessageCard({
    super.key,
    required this.message,
    this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final isEmergency = message.isEmergency;
    final isMe = message.isSentByMe;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEmergency
            ? AppColors.emergencyDark.withValues(alpha: 0.35)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmergency
              ? AppColors.emergency.withValues(alpha: 0.6)
              : (isMe
                  ? AppColors.primaryAccent.withValues(alpha: 0.25)
                  : AppColors.border),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sender & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isMe ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: isEmergency
                          ? AppColors.emergency
                          : (isMe
                              ? AppColors.primaryAccent
                              : AppColors.secondaryAccent),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message.sender,
                        style: AppTypography.supportingSecondary.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isEmergency
                              ? AppColors.emergency
                              : (isMe
                                  ? AppColors.primaryAccent
                                  : AppColors.secondaryAccent),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isEmergency) ...[
                      const SizedBox(width: 8),
                      const StatusChip(
                        label: 'PRIORITY',
                        color: AppColors.emergency,
                        icon: Icons.priority_high,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.time(message.timestamp),
                style: AppTypography.supporting,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Message Text
          Text(
            '"${message.text}"',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          // Footer info row: Language pair, status, and optional replay
          Row(
            children: [
              // Language badge
              Text(
                message.language,
                style: AppTypography.supporting.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 11,
                ),
              ),
              const Spacer(),

              // Replay action (if received)
              if (!isMe && onReplay != null) ...[
                InkWell(
                  onTap: onReplay,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.volume_up,
                          size: 13,
                          color: AppColors.primaryAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hear',
                          style: AppTypography.supporting.copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Status Tag
              Row(
                children: [
                  Icon(
                    message.status == MessageStatus.failed
                        ? Icons.error_outline
                        : Icons.check,
                    size: 12,
                    color: message.status == MessageStatus.failed
                        ? AppColors.emergency
                        : (isEmergency
                            ? AppColors.emergency
                            : AppColors.connected),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    message.status.label,
                    style: AppTypography.supporting.copyWith(
                      color: message.status == MessageStatus.failed
                          ? AppColors.emergency
                          : (isEmergency
                              ? AppColors.emergency
                              : AppColors.connected),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
