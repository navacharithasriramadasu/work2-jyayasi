import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/status_chip.dart';

/// About screen detailing the core iTantra vision, system specs, and problem statement alignment.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'About iTantra',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Logo & Title
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.primaryAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.cell_tower,
                color: AppColors.primaryAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              AppConstants.appName,
              style: AppTypography.display.copyWith(
                fontSize: 26,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              AppConstants.appTagline,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.secondaryAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Description Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'iTantra converts speech into text locally, transmits compact text through a low-bandwidth local connection (Wi-Fi Direct or Bluetooth), and reconstructs speech on the receiving device through on-device neural Text-to-Speech.\n\nDesigned for mission-critical, disaster response, and remote operations where cellular and cloud infrastructure are degraded or unavailable.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features Checklist
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CORE CAPABILITIES',
                    style: AppTypography.supporting.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFeatureItem('Offline AI on-device inference'),
                  _buildFeatureItem('10 Indian multilingual languages'),
                  _buildFeatureItem('Low-bandwidth text transmission (~50 Bytes/message)'),
                  _buildFeatureItem('Peer-to-peer Wi-Fi Direct and Bluetooth'),
                  _buildFeatureItem('Tactical Push-to-Talk communication'),
                  _buildFeatureItem('Emergency priority broadcast channel'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Version Badge
            const StatusChip(
              label: AppConstants.version,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 8),

            Text(
              'SIH26173 Problem Statement Solution',
              style: AppTypography.supporting.copyWith(
                color: AppColors.mutedText,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.connected,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
