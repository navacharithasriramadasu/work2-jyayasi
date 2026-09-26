import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/connection_model.dart';

/// Small technical status indicator with pulsing dot.
class AppStatusIndicator extends StatefulWidget {
  final ConnectionStatus status;
  final String? customLabel;
  final bool showPulse;

  const AppStatusIndicator({
    super.key,
    required this.status,
    this.customLabel,
    this.showPulse = true,
  });

  @override
  State<AppStatusIndicator> createState() => _AppStatusIndicatorState();
}

class _AppStatusIndicatorState extends State<AppStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.status) {
      case ConnectionStatus.connected:
        return AppColors.connected;
      case ConnectionStatus.scanning:
      case ConnectionStatus.connecting:
        return AppColors.warning;
      case ConnectionStatus.disconnected:
        return AppColors.mutedText;
      case ConnectionStatus.error:
        return AppColors.emergency;
    }
  }

  String get _defaultLabel {
    switch (widget.status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.scanning:
        return 'Scanning...';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Link Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final label = widget.customLabel ?? _defaultLabel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final alpha = widget.showPulse &&
                    (widget.status == ConnectionStatus.connected ||
                        widget.status == ConnectionStatus.connecting)
                ? _pulseAnimation.value
                : 1.0;
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: alpha),
                boxShadow: widget.status == ConnectionStatus.connected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5 * alpha),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.supportingSecondary.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
