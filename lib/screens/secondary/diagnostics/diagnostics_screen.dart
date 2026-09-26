import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/device_model.dart';
import '../../../providers/connection_provider.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_status_indicator.dart';
import '../../../widgets/pipeline_step.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_chip.dart';

/// Technical link diagnostics and full architectural pipeline visualizer.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionProvider);
    final device = connection.connectedDevice;

    return AppScaffold(
      title: 'Connection Diagnostics',
      showBack: true,
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
            // Status Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDiagRow('Target Device', device?.name ?? 'iTantra-Rescue-01'),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Link Transport',
                    device?.connectionType.label ?? connection.preferredTransport.label,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Radio Link State',
                    connection.isConnected ? 'Connected & Synced' : 'Disconnected',
                    valueColor: connection.isConnected
                        ? AppColors.connected
                        : AppColors.emergency,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Signal Quality',
                    Formatters.signalStrength(device?.signalStrength ?? 0.9),
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow('Air Transmission', 'TEXT ONLY (ASCII/UTF-8)'),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Audio Transmission',
                    'DISABLED',
                    valueColor: AppColors.secondaryAccent,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Cloud Dependency',
                    'NOT REQUIRED (Air-gapped)',
                    valueColor: AppColors.connected,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Complete Technical Pipeline Breakdown
            const SectionHeader(
              title: 'Full Transceiver Architecture',
              trailing: StatusChip(
                label: 'END-TO-END FLOW',
                color: AppColors.primaryAccent,
              ),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: 'MICROPHONE',
                    subtitle: 'Raw acoustic voice capture',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: 'PAUSE DETECTION',
                    subtitle: 'Voice activity detection & sentence boundary',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: 'LOCAL STT',
                    subtitle: 'On-device acoustic to text transformation',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: 'TEXT PAYLOAD',
                    subtitle: 'Compact compressed string (~30-80 Bytes)',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: 'WI-FI DIRECT / BLUETOOTH',
                    subtitle: 'Local P2P radio packet transmission',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: 'TEXT RECEPTION',
                    subtitle: 'Peer radio reception verification',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: 'LOCAL TTS',
                    subtitle: 'On-device text to acoustic synthesis',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: 'SPEAKER',
                    subtitle: 'Receiver hears reconstructed voice',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagRow(String key, String val, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            key,
            style: AppTypography.supporting.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            val,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}
