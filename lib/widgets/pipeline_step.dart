import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

enum PipelineStepState {
  completed,
  active,
  pending,
}

/// A vertical pipeline step visualization for processing, sending, and diagnostics.
class PipelineStep extends StatelessWidget {
  final PipelineStepState state;
  final String title;
  final String? subtitle;
  final bool isLast;

  const PipelineStep({
    super.key,
    required this.state,
    required this.title,
    this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Widget iconWidget;

    switch (state) {
      case PipelineStepState.completed:
        iconColor = AppColors.connected;
        iconWidget = Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.check, size: 14, color: AppColors.connected),
          ),
        );
        break;
      case PipelineStepState.active:
        iconColor = AppColors.primaryAccent;
        iconWidget = Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primaryAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
        break;
      case PipelineStepState.pending:
        iconColor = AppColors.disabled;
        iconWidget = Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon and vertical connector column
        Column(
          children: [
            iconWidget,
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: state == PipelineStepState.completed
                    ? AppColors.connected.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Text labels
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: state == PipelineStepState.active
                        ? FontWeight.w700
                        : (state == PipelineStepState.completed
                            ? FontWeight.w600
                            : FontWeight.w400),
                    color: state == PipelineStepState.pending
                        ? AppColors.mutedText
                        : AppColors.primaryText,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.supporting.copyWith(
                      color: state == PipelineStepState.active
                          ? AppColors.primaryAccent
                          : AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
