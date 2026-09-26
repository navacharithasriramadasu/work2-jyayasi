import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/connection_model.dart';
import '../../models/device_model.dart';
import '../../providers/connection_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/primary_action_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

/// Initial transceiver onboarding & setup screen.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  CommunicationMode _selectedMode = CommunicationMode.walkieTalkie;
  ConnectionType _selectedConnection = ConnectionType.wifiDirect;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Initial Setup',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Subtitle
            Text(
              'Set up your communication',
              style: AppTypography.screenTitle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how iTantra should communicate.',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: 24),

            // Communication Mode Section
            const SectionHeader(title: 'Communication Mode'),
            _buildModeOption(
              mode: CommunicationMode.walkieTalkie,
              title: 'Walkie-Talkie',
              subtitle: 'Press and hold to speak',
              icon: Icons.mic_none,
            ),
            const SizedBox(height: 10),
            _buildModeOption(
              mode: CommunicationMode.continuous,
              title: 'Normal Communication',
              subtitle: 'Continuous communication experience',
              icon: Icons.headset_mic_outlined,
            ),
            const SizedBox(height: 24),

            // Connection Section
            const SectionHeader(title: 'Local Transport Link'),
            _buildConnectionOption(
              type: ConnectionType.wifiDirect,
              title: 'Wi-Fi Direct',
              subtitle: 'Fast local peer-to-peer communication',
              icon: Icons.wifi_tethering,
            ),
            const SizedBox(height: 10),
            _buildConnectionOption(
              type: ConnectionType.bluetooth,
              title: 'Bluetooth',
              subtitle: 'Nearby device communication (low energy)',
              icon: Icons.bluetooth,
            ),
            const SizedBox(height: 24),

            // Privacy Guarantee Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.secondaryAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.security,
                    color: AppColors.secondaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const StatusChip(
                          label: 'LOCAL PRIVACY',
                          color: AppColors.secondaryAccent,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your voice and messages are processed locally on this device. No raw audio ever leaves your phone.',
                          style: AppTypography.supporting.copyWith(
                            color: AppColors.primaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            PrimaryActionButton(
              label: 'Continue',
              onPressed: () {
                ref.read(settingsProvider.notifier).setCommunicationMode(_selectedMode);
                ref.read(connectionProvider.notifier).setPreferredTransport(_selectedConnection);
                context.go('/home');
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Skip to Dashboard',
                  style: AppTypography.button.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required CommunicationMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.elevatedSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryAccent : AppColors.mutedText,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.supporting,
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryAccent : AppColors.mutedText,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionOption({
    required ConnectionType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedConnection == type;

    return InkWell(
      onTap: () => setState(() => _selectedConnection = type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.elevatedSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryAccent : AppColors.mutedText,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.supporting,
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryAccent : AppColors.mutedText,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
