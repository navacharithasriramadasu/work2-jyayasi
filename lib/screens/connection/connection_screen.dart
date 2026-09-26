import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/device_model.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_status_indicator.dart';
import '../../widgets/device_card.dart';
import '../../widgets/primary_action_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

/// Device discovery, scan, and radio pairing screen.
class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionProvider.notifier).scanDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(connectionProvider);
    final activeTransport = connection.preferredTransport;

    return AppScaffold(
      title: 'Connect Device',
      showBack: true,
      subtitleWidget: Text(
        'Connect to another nearby iTantra device.',
        style: AppTypography.supporting,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: AppStatusIndicator(
            status: connection.status,
            showPulse: connection.isConnected,
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transport Tabs (Wi-Fi Direct / Bluetooth)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildTab(
                    type: ConnectionType.wifiDirect,
                    label: 'Wi-Fi Direct',
                    icon: Icons.wifi,
                    isSelected: activeTransport == ConnectionType.wifiDirect,
                  ),
                  _buildTab(
                    type: ConnectionType.bluetooth,
                    label: 'Bluetooth',
                    icon: Icons.bluetooth,
                    isSelected: activeTransport == ConnectionType.bluetooth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Connected State (if any)
            if (connection.isConnected && connection.connectedDevice != null) ...[
              const SectionHeader(title: 'Active Link'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.connected.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.connected.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.connected,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  connection.connectedDevice!.name,
                                  style: AppTypography.screenTitle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const StatusChip(
                                label: 'LINKED',
                                color: AppColors.connected,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${connection.connectedDevice!.connectionType.label} • Strong Signal',
                            style: AppTypography.supporting.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.link_off, color: AppColors.mutedText),
                      tooltip: 'Disconnect',
                      onPressed: () {
                        ref.read(connectionProvider.notifier).disconnect();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Nearby Devices Header
            SectionHeader(
              title: 'Nearby Devices',
              trailing: connection.isScanning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            const SizedBox(height: 4),

            // Discovered Devices List
            if (connection.discoveredDevices.isEmpty && !connection.isScanning)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No transceivers found. Tap Scan Again.',
                    style: AppTypography.supporting,
                  ),
                ),
              )
            else
              ...connection.discoveredDevices.map((device) {
                return DeviceCard(
                  device: device.copyWith(
                    isConnected: connection.connectedDevice?.id == device.id,
                  ),
                  isConnecting: connection.isConnecting,
                  onConnect: () {
                    ref.read(connectionProvider.notifier).connect(device);
                  },
                );
              }),

            const SizedBox(height: 12),

            // Scan Again button
            PrimaryActionButton(
              label: 'Scan Again',
              variant: ActionButtonVariant.secondary,
              icon: Icons.refresh,
              isLoading: connection.isScanning,
              onPressed: () {
                ref.read(connectionProvider.notifier).scanDevices();
              },
            ),
            const SizedBox(height: 16),

            // Start Communication
            if (connection.isConnected)
              PrimaryActionButton(
                label: 'Start Communication',
                icon: Icons.mic,
                onPressed: () => context.go('/home'),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required ConnectionType type,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(connectionProvider.notifier).setPreferredTransport(type);
          ref.read(connectionProvider.notifier).scanDevices();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.elevatedSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppColors.primaryAccent, width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.primaryAccent
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  fontSize: 12,
                  color: isSelected
                      ? AppColors.primaryAccent
                      : AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
