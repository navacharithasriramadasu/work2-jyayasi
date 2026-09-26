import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Compact tactical badge pill.
class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool isGlowing;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.isGlowing = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.35),
          width: 0.8,
        ),
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.25),
                  blurRadius: 6,
                  spreadRadius: 0,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.supporting.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
