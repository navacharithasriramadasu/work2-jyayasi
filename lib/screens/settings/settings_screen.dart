import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/connection_model.dart';
import '../../models/device_model.dart';
import '../../providers/connection_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

/// Settings screen organizing radio transport, language defaults, and on-device AI controls.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final languages = ref.watch(languageProvider);
    final connection = ref.watch(connectionProvider);

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. COMMUNICATION
          const SectionHeader(title: 'Communication'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'Connection Transport',
              subtitle: connection.preferredTransport.label,
              icon: Icons.wifi_tethering,
              onTap: () => context.push('/connect'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'Communication Mode',
              subtitle: settings.communicationMode == CommunicationMode.walkieTalkie
                  ? 'Walkie-Talkie (Push-to-Talk)'
                  : 'Continuous Communication',
              icon: Icons.mic_none,
              onTap: () => context.push('/setup'),
            ),
          ]),
          const SizedBox(height: 20),

          // 2. LANGUAGE
          const SectionHeader(title: 'Language'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'Your Language',
              subtitle: '${languages.senderLanguage.englishName} (${languages.senderLanguage.nativeName})',
              icon: Icons.translate,
              onTap: () => context.push('/languages'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'Receiver Language',
              subtitle: '${languages.receiverLanguage.englishName} (${languages.receiverLanguage.nativeName})',
              icon: Icons.record_voice_over,
              onTap: () => context.push('/languages'),
            ),
          ]),
          const SizedBox(height: 20),

          // 3. AI
          const SectionHeader(title: 'On-Device AI Engine'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'Speech Recognition',
              subtitle: 'On-device neural model',
              icon: Icons.graphic_eq,
              trailing: const StatusChip(label: 'LOCAL', color: AppColors.secondaryAccent),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'Voice Output (TTS)',
              subtitle: 'On-device synthesizer',
              icon: Icons.volume_up,
              trailing: const StatusChip(label: 'LOCAL', color: AppColors.secondaryAccent),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'Cloud Processing',
              subtitle: 'Offline air-gapped pipeline',
              icon: Icons.cloud_off,
              trailing: const StatusChip(label: 'OFF', color: AppColors.mutedText),
            ),
          ]),
          const SizedBox(height: 20),

          // 4. PERFORMANCE & DIAGNOSTICS
          const SectionHeader(title: 'Performance & Diagnostics'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'AI Model Information',
              subtitle: 'Whisper-Tiny / Piper quantized INT8',
              icon: Icons.memory,
              onTap: () => context.push('/ai-info'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'Connection Diagnostics',
              subtitle: 'Link status, packet latency, and radio stats',
              icon: Icons.insights,
              onTap: () => context.push('/diagnostics'),
            ),
          ]),
          const SizedBox(height: 20),

          // 5. PRIVACY
          const SectionHeader(title: 'Privacy'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'Voice Processing',
              subtitle: 'Local on-chip execution only. No audio egress.',
              icon: Icons.verified_user_outlined,
              trailing: const StatusChip(label: 'LOCAL ONLY', color: AppColors.connected),
            ),
          ]),
          const SizedBox(height: 20),

          // 6. SECONDARY NAVIGATION
          const SectionHeader(title: 'System & Diagnostics Pages'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'Communication Languages',
              subtitle: '10 Indian languages with native scripts',
              icon: Icons.language,
              onTap: () => context.push('/languages'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'AI Information',
              subtitle: 'On-device engine architecture and specs',
              icon: Icons.memory,
              onTap: () => context.push('/ai-info'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'Connection Diagnostics',
              subtitle: 'Radio parameters and 8-stage pipeline',
              icon: Icons.insights,
              onTap: () => context.push('/diagnostics'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'About iTantra',
              subtitle: 'Vision, problem statement, version 1.0',
              icon: Icons.info_outline,
              onTap: () => context.push('/about'),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryAccent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.supporting,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing,
            ] else if (onTap != null) ...[
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.mutedText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
