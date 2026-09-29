import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/device_model.dart';
import '../../../providers/connection_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_status_indicator.dart';
import '../../../widgets/pipeline_step.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_chip.dart';

/// Technical link diagnostics, real GPS coordinates, and full architectural pipeline visualizer.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  int? _pingLatencyMs;
  bool _isPinging = false;

  Future<void> _runPingTest() async {
    setState(() => _isPinging = true);
    final stopwatch = Stopwatch()..start();
    final api = ref.read(apiServiceProvider);
    final ok = await api.checkHealth();
    stopwatch.stop();

    if (mounted) {
      setState(() {
        _isPinging = false;
        _pingLatencyMs = ok ? stopwatch.elapsedMilliseconds : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(connectionProvider);
    final device = connection.connectedDevice;
    final location = ref.watch(locationServiceProvider);
    final ws = ref.watch(webSocketServiceProvider);

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
                  _buildDiagRow('Callsign & Node', '${ApiConfig.callsign} (${ApiConfig.deviceId})'),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow('Active Radio Channel', device?.name ?? ApiConfig.activeChannelId),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Link Transport',
                    device?.connectionType.label ?? connection.preferredTransport.label,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Radio Link State',
                    connection.isConnected ? 'Connected & Synced' : 'Disconnected / Standalone',
                    valueColor: connection.isConnected
                        ? AppColors.connected
                        : AppColors.secondaryAccent,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'WebSocket Gateway',
                    ws.status.name.toUpperCase(),
                    valueColor: ws.status.name == 'connected'
                        ? AppColors.connected
                        : AppColors.mutedText,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'GPS Telemetry',
                    location.formattedCoordinates,
                    valueColor: location.hasGpsLock ? AppColors.connected : AppColors.secondaryAccent,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Signal Quality',
                    Formatters.signalStrength(device?.signalStrength ?? 0.95),
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow('Air Transmission', 'TEXT ONLY (ASCII/UTF-8)'),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Audio Transmission',
                    'DISABLED (99.9% Bitrate Reduction)',
                    valueColor: AppColors.connected,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildDiagRow(
                    'Local AI Inference',
                    'ON-DEVICE (Air-Gapped)',
                    valueColor: AppColors.connected,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Network Ping Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gateway Round-Trip Ping',
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pingLatencyMs != null
                            ? '$_pingLatencyMs ms (HTTP Healthz)'
                            : (connection.isConnected ? 'Ready for test' : 'Offline mesh link'),
                        style: AppTypography.supporting.copyWith(
                          color: _pingLatencyMs != null ? AppColors.connected : AppColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.elevatedSurface,
                      foregroundColor: AppColors.primaryAccent,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: _isPinging ? null : _runPingTest,
                    icon: _isPinging
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt, size: 16),
                    label: const Text('PING TEST'),
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
                    title: '1. MICROPHONE INPUT',
                    subtitle: 'Raw acoustic voice capture at 16 kHz PCM',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: '2. VOICE ACTIVITY DETECTION',
                    subtitle: 'Energy thresholding & sentence boundary pause detection',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: '3. ON-DEVICE STT INFERENCE',
                    subtitle: 'Quantized neural model converts acoustic frames to text',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: '4. TOKENIZED TEXT PAYLOAD',
                    subtitle: 'Ultra-compact compressed string (~30-80 Bytes)',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: '5. LOW-BITRATE RADIO LINK',
                    subtitle: 'Wi-Fi Direct / BLE Mesh / UHF Packet Transmission',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: '6. PEER TEXT RECEPTION',
                    subtitle: 'Receiver parses tokenized text and validates checksum',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: '7. ON-DEVICE TTS INFERENCE',
                    subtitle: 'Neural voice synthesizer reconstructs speech in target language',
                  ),
                  PipelineStep(
                    state: PipelineStepState.completed,
                    title: '8. SPEAKER AUDIO PLAYBACK',
                    subtitle: 'Receiver hears reconstructed voice with zero audio transmitted',
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

  Widget _buildDiagRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.supportingSecondary.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.primaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
