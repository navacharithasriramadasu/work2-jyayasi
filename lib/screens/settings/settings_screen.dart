import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/connection_model.dart';
import '../../models/device_model.dart';
import '../../providers/connection_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

/// Settings screen organizing node identity, environment gateway, language pairs, and on-device AI controls.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showCallsignDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: ApiConfig.callsign);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit Device Callsign', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set tactical identifier broadcast over radio links:', style: AppTypography.supporting),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: AppTypography.bodyMedium,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. ALPHA-1, BRAVO-LEADER',
                filled: true,
                fillColor: AppColors.elevatedSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
            onPressed: () {
              final newCallsign = controller.text.trim();
              if (newCallsign.isNotEmpty) {
                ref.read(deviceSettingsServiceProvider).setCallsign(newCallsign);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEnvironmentDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Gateway Environment', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text('Switch backend gateway for hackathon demonstrations:', style: AppTypography.supporting),
            const SizedBox(height: 16),
            ...BackendEnvironment.values.map((env) {
              final isSelected = ApiConfig.environment == env;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected ? AppColors.elevatedSurface : Colors.transparent,
                title: Text(env.name.toUpperCase(), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  env == BackendEnvironment.production
                      ? 'Production Cloud (Render)'
                      : env == BackendEnvironment.emulator
                          ? 'Android Emulator (10.0.2.2:3000)'
                          : env == BackendEnvironment.lan
                              ? 'Local LAN Mesh Node'
                              : 'Custom Radio Hub',
                  style: AppTypography.supporting,
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.connected) : null,
                onTap: () {
                  ref.read(deviceSettingsServiceProvider).setEnvironment(env);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final languages = ref.watch(languageProvider);
    final connection = ref.watch(connectionProvider);
    final location = ref.watch(locationServiceProvider);

    return AppScaffold(
      title: 'Settings & Node Config',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. TACTICAL NODE IDENTITY
          const SectionHeader(title: 'Node Identity'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'Tactical Callsign',
              subtitle: ApiConfig.callsign,
              icon: Icons.badge,
              trailing: const StatusChip(label: 'EDIT', color: AppColors.primaryAccent),
              onTap: () => _showCallsignDialog(context, ref),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'Hardware Node ID',
              subtitle: ApiConfig.deviceId,
              icon: Icons.fingerprint,
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'GPS Telemetry Lock',
              subtitle: '${location.formattedCoordinates} (${location.hasGpsLock ? "Hardware Lock" : "Grid Coords"})',
              icon: Icons.my_location,
              trailing: IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: AppColors.primaryAccent),
                tooltip: 'Refresh GPS',
                onPressed: () => location.updateCurrentLocation(),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // 2. RADIO GATEWAY & ENVIRONMENT
          const SectionHeader(title: 'Radio Gateway Environment'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'Active Environment',
              subtitle: '${ApiConfig.environment.name.toUpperCase()} • ${ApiConfig.baseUrl}',
              icon: Icons.dns,
              trailing: const StatusChip(label: 'SWITCH', color: AppColors.connected),
              onTap: () => _showEnvironmentDialog(context, ref),
            ),
            const Divider(color: AppColors.border, height: 1),
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

          // 3. LANGUAGE
          const SectionHeader(title: 'Language Configuration'),
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

          // 4. ON-DEVICE AI
          const SectionHeader(title: 'On-Device AI Engine'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'Speech Recognition (STT)',
              subtitle: 'On-device neural model • 10 Indian Languages',
              icon: Icons.graphic_eq,
              trailing: const StatusChip(label: 'LOCAL', color: AppColors.secondaryAccent),
              onTap: () => context.push('/ai-info'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'Voice Output (TTS)',
              subtitle: 'On-device neural synthesizer • Low-Latency',
              icon: Icons.volume_up,
              trailing: const StatusChip(label: 'LOCAL', color: AppColors.secondaryAccent),
              onTap: () => context.push('/ai-info'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'Air Transmission Model',
              subtitle: 'Compact tokenized text only (99.9% bandwidth reduction)',
              icon: Icons.compress,
              trailing: const StatusChip(label: '99.9% SAVINGS', color: AppColors.connected),
            ),
          ]),
          const SizedBox(height: 20),

          // 5. SYSTEM & DIAGNOSTICS
          const SectionHeader(title: 'Diagnostics & Hackathon Info'),
          _buildSettingsGroup([
            _buildSettingRow(
              title: 'Connection Diagnostics',
              subtitle: 'Radio parameters, WebSocket state, and 8-stage pipeline',
              icon: Icons.insights,
              onTap: () => context.push('/diagnostics'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'AI Model Benchmarks',
              subtitle: 'Inference latency, RAM footprint, and model sizes',
              icon: Icons.memory,
              onTap: () => context.push('/ai-info'),
            ),
            const Divider(color: AppColors.border, height: 1),
            _buildSettingRow(
              title: 'About iTantra (ISRO SIH26173)',
              subtitle: 'Problem statement, innovation summary, and team details',
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
