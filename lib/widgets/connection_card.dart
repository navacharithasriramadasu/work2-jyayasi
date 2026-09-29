import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/connection_model.dart';
import '../models/device_model.dart';
import '../core/utils/formatters.dart';
import 'app_status_indicator.dart';

/// Connection badge card displayed on the Home Screen.
class ConnectionCard extends StatelessWidget {
  final ConnectionStatus status;
  final DeviceModel? device;
  final VoidCallback? onTap;

  const ConnectionCard({
    super.key,
    required this.status,
    this.device,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = status == ConnectionStatus.connected && device != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConnected
                  ? AppColors.primaryAccent.withValues(alpha: 0.3)
                  : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Radio Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isConnected ? AppColors.primaryAccent : AppColors.mutedText)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isConnected
                            ? AppColors.primaryAccent
                            : AppColors.mutedText)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  device?.connectionType == ConnectionType.bluetooth
                      ? Icons.bluetooth
                      : Icons.wifi_tethering,
                  color: isConnected ? AppColors.primaryAccent : AppColors.mutedText,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Device details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isConnected ? 'Connected to' : 'Radio Link',
                          style: AppTypography.supporting,
                        ),
                        const Spacer(),
                        AppStatusIndicator(
                          status: status,
                          showPulse: isConnected,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected
                          ? (device?.name ?? 'COMMAND_NET (434.25 MHz)')
                          : 'No Device Paired',
                      style: AppTypography.screenTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          isConnected
                              ? device!.connectionType.label
                              : 'Tap to scan devices',
                          style: AppTypography.supportingSecondary.copyWith(
                            color: isConnected
                                ? AppColors.secondaryAccent
                                : AppColors.mutedText,
                          ),
                        ),
                        if (isConnected) ...[
                          Text(
                            '•',
                            style: AppTypography.supporting
                                .copyWith(color: AppColors.mutedText),
                          ),
                          Text(
                            'Signal: ${Formatters.signalStrength(device!.signalStrength)}',
                            style: AppTypography.supporting.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
