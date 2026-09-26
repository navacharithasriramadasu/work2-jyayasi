import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/metric_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_chip.dart';

/// Technical overview of On-Device AI models and truthful performance indicators.
class AiInfoScreen extends StatelessWidget {
  const AiInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'On-Device AI',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Core Architecture Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.memory,
                        color: AppColors.primaryAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'LOCAL INFERENCE PIPELINE',
                        style: AppTypography.supporting.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'iTantra runs all speech recognition and acoustic synthesis locally on the device hardware. No audio packets or voice biometric data are ever sent over network interfaces.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4 Status Blocks
            const SectionHeader(title: 'Engine Architecture'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.18,
              children: [
                _buildStatusBlock(
                  label: 'Speech Recognition',
                  badge: 'ON DEVICE',
                  icon: Icons.mic,
                  color: AppColors.secondaryAccent,
                ),
                _buildStatusBlock(
                  label: 'Text-to-Speech',
                  badge: 'ON DEVICE',
                  icon: Icons.volume_up,
                  color: AppColors.secondaryAccent,
                ),
                _buildStatusBlock(
                  label: 'Cloud Dependency',
                  badge: 'NONE',
                  icon: Icons.cloud_off,
                  color: AppColors.connected,
                ),
                _buildStatusBlock(
                  label: 'Air Transmission',
                  badge: 'TEXT ONLY',
                  icon: Icons.text_snippet,
                  color: AppColors.primaryAccent,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Truthful Performance Benchmarks
            const SectionHeader(
              title: 'Hardware Benchmark Metrics',
              trailing: StatusChip(
                label: 'PENDING ON-DEVICE RUN',
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 6),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.22,
              children: const [
                MetricCard(
                  label: 'Model Size',
                  value: '--',
                  unit: 'MB',
                  icon: Icons.save,
                ),
                MetricCard(
                  label: 'RAM Usage',
                  value: '--',
                  unit: 'MB',
                  icon: Icons.memory,
                ),
                MetricCard(
                  label: 'Inference Time',
                  value: '--',
                  unit: 'ms',
                  icon: Icons.timer,
                ),
                MetricCard(
                  label: 'End-to-End Latency',
                  value: '--',
                  unit: 'ms',
                  icon: Icons.speed,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Truthful note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Performance depends on device chipset (NPU/DSP), language complexity, and selected quantization model. Actual benchmarks will populate during live device calibration.',
                style: AppTypography.supporting.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBlock({
    required String label,
    required String badge,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: color),
              StatusChip(label: badge, color: color),
            ],
          ),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
