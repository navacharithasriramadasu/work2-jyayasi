import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/formatters.dart';
import '../models/device_model.dart';
import 'status_chip.dart';

/// Device discovery card showing signal quality and connect button.
class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onConnect;
  final bool isConnecting;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onConnect,
    this.isConnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = device.isConnected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected ? AppColors.primaryAccent : AppColors.border,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Radio Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              device.connectionType == ConnectionType.bluetooth
                  ? Icons.bluetooth
                  : Icons.wifi,
              color: isConnected ? AppColors.connected : AppColors.primaryText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${Formatters.signalStrength(device.signalStrength)} Signal',
                        style: AppTypography.supporting.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: AppTypography.supporting.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      device.connectionType.label,
                      style: AppTypography.supporting.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Connect / Connected Action
          if (isConnected)
            const StatusChip(
              label: 'CONNECTED',
              color: AppColors.connected,
              icon: Icons.check_circle,
            )
          else
            SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.elevatedSurface,
                  foregroundColor: AppColors.primaryAccent,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.borderBright),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isConnecting ? null : onConnect,
                child: isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'CONNECT',
                        style: AppTypography.button.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.primaryAccent,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
