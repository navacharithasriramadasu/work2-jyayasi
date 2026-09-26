import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/emergency_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/emergency_button.dart';
import '../../widgets/primary_action_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

/// Single unified Emergency screen with dynamic in-screen state machine:
/// IDLE → CONFIRMING → SENDING → SENT → RECEIVED.
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  String _selectedPreset = AppConstants.emergencyPresets.first;

  @override
  Widget build(BuildContext context) {
    final emergency = ref.watch(emergencyProvider);

    return AppScaffold(
      title: 'Emergency Communication',
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStateView(emergency),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateView(EmergencyStateModel emergency) {
    if (emergency.isConfirming) {
      return _buildConfirmingState(emergency);
    } else if (emergency.isSending) {
      return _buildSendingState();
    } else if (emergency.isSent) {
      return _buildSentState(emergency);
    } else if (emergency.isReceived) {
      return _buildReceivedState(emergency);
    }
    // Default: IDLE state
    return _buildIdleState();
  }

  // --------------------------------------------------------------------------
  // STATE: IDLE
  // --------------------------------------------------------------------------
  Widget _buildIdleState() {
    return Padding(
      key: const ValueKey('emergency_idle'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.emergency, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Send a priority message when communication is critical.',
                  style: AppTypography.supportingSecondary.copyWith(color: AppColors.primaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Large Circular Tactical Emergency Button
          Center(
            child: EmergencyButton(
              label: 'HOLD FOR EMERGENCY',
              subtitle: 'Release to confirm priority alert',
              onTrigger: () {
                ref.read(emergencyProvider.notifier).arm(_selectedPreset);
              },
            ),
          ),
          const SizedBox(height: 28),

          // Predefined Alerts Section
          const SectionHeader(
            title: 'Select Predefined Priority Alert',
            trailing: StatusChip(label: 'IMMEDIATE OVERRIDE', color: AppColors.emergency),
          ),
          const SizedBox(height: 6),

          ...AppConstants.emergencyPresets.map((preset) {
            final isSelected = _selectedPreset == preset;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.emergency : AppColors.border,
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Material(
                color: isSelected
                    ? AppColors.emergencyDark.withValues(alpha: 0.5)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  dense: true,
                  title: Text(
                    preset,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.emergency, size: 18)
                      : null,
                  onTap: () {
                    setState(() => _selectedPreset = preset);
                    ref.read(emergencyProvider.notifier).selectPreset(preset);
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          PrimaryActionButton(
            label: 'Speak Emergency Message',
            icon: Icons.mic,
            variant: ActionButtonVariant.secondary,
            onPressed: () {
              ref
                  .read(emergencyProvider.notifier)
                  .arm('Emergency vocal dispatch at location coordinates.');
            },
          ),
          const SizedBox(height: 12),

          // Demo trigger to simulate receiving incoming emergency broadcast
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.download, size: 16, color: AppColors.emergency),
              label: Text(
                'Simulate Incoming Priority Alert (Demo)',
                style: AppTypography.supporting.copyWith(
                  color: AppColors.emergency,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                ref.read(emergencyProvider.notifier).simulateReceiveEmergency(
                      text: 'Medical emergency. Immediate assistance required.',
                      sender: 'iTantra-Rescue-01',
                    );
              },
            ),
          ),
          const SizedBox(height: 8),

          Center(
            child: Text(
              'Priority messages are announced immediately on the receiving device.',
              textAlign: TextAlign.center,
              style: AppTypography.supporting.copyWith(color: AppColors.mutedText, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE: CONFIRMING
  // --------------------------------------------------------------------------
  Widget _buildConfirmingState(EmergencyStateModel emergency) {
    return Padding(
      key: const ValueKey('emergency_confirming'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          const Spacer(),

          const StatusChip(
            label: 'HIGH PRIORITY TRANSMISSION',
            color: AppColors.emergency,
            icon: Icons.warning,
            isGlowing: true,
          ),
          const SizedBox(height: 16),

          Text(
            'Send Emergency Message?',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 22,
              color: AppColors.emergency,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This is a priority transmission.',
            style: AppTypography.bodySecondary.copyWith(
              color: AppColors.emergency,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.emergencyDark.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.emergency, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BROADCAST PAYLOAD',
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.emergency,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '"${emergency.activeMessageText}"',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Center(
            child: EmergencyButton(
              label: 'HOLD TO CONFIRM',
              subtitle: 'Release to transmit priority broadcast',
              onTrigger: () async {
                await ref.read(emergencyProvider.notifier).confirmAndSend();
              },
            ),
          ),

          const Spacer(),

          PrimaryActionButton(
            label: 'Cancel',
            variant: ActionButtonVariant.secondary,
            onPressed: () {
              ref.read(emergencyProvider.notifier).cancel();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE: SENDING
  // --------------------------------------------------------------------------
  Widget _buildSendingState() {
    return Padding(
      key: const ValueKey('emergency_sending'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emergencyDark,
                border: Border.all(color: AppColors.emergency, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emergency.withValues(alpha: 0.5),
                    blurRadius: 28,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Icons.emergency, size: 48, color: AppColors.emergency),
            ),
            const SizedBox(height: 24),
            Text(
              'PRIORITY TRANSMITTING...',
              style: AppTypography.screenTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: AppColors.emergency,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Broadcasting on dedicated emergency radio channel',
              style: AppTypography.supporting.copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE: SENT
  // --------------------------------------------------------------------------
  Widget _buildSentState(EmergencyStateModel emergency) {
    final text = emergency.sentEmergencyMessage?.text ?? emergency.activeMessageText;

    return Padding(
      key: const ValueKey('emergency_sent'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          const Spacer(),

          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.emergencyDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emergency, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emergency.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.emergency, size: 42),
          ),
          const SizedBox(height: 20),

          Text(
            'PRIORITY TRANSMITTED',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppColors.emergency,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.connected, size: 16),
              const SizedBox(width: 6),
              Text(
                'Delivered over Wi-Fi Direct',
                style: AppTypography.supportingSecondary.copyWith(
                  color: AppColors.connected,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.emergency.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusChip(label: 'PRIORITY TEXT PAYLOAD', color: AppColors.emergency),
                const SizedBox(height: 12),
                Text(
                  '"$text"',
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                Text(
                  'Receiver will announce this message immediately.',
                  style: AppTypography.supporting.copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),

          const Spacer(),

          PrimaryActionButton(
            label: 'Back to Communication',
            onPressed: () {
              ref.read(emergencyProvider.notifier).acknowledge();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE: RECEIVED
  // --------------------------------------------------------------------------
  Widget _buildReceivedState(EmergencyStateModel emergency) {
    final msg = emergency.receivedEmergencyMessage;
    final text = msg?.text ?? 'Medical emergency. Immediate assistance required.';
    final sender = msg?.sender ?? 'iTantra-Rescue-01';

    return Padding(
      key: const ValueKey('emergency_received'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          const Spacer(),

          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.emergencyDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emergency, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emergency.withValues(alpha: 0.5),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.warning, color: AppColors.emergency, size: 46),
          ),
          const SizedBox(height: 20),

          const StatusChip(
            label: 'VOICE ANNOUNCEMENT ACTIVE',
            color: AppColors.emergency,
            icon: Icons.volume_up,
            isGlowing: true,
          ),
          const SizedBox(height: 10),

          Text(
            'PRIORITY MESSAGE',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppColors.emergency,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Origin: $sender',
            style: AppTypography.supportingSecondary.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.emergencyDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.emergency, width: 2.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMERGENCY BROADCAST',
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.emergency,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '"$text"',
                  style: AppTypography.screenTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: PrimaryActionButton(
                  label: 'Replay Alert',
                  icon: Icons.replay,
                  variant: ActionButtonVariant.secondary,
                  onPressed: () {
                    ref.read(emergencyProvider.notifier).replay();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryActionButton(
                  label: 'Acknowledge',
                  icon: Icons.check,
                  variant: ActionButtonVariant.danger,
                  onPressed: () {
                    ref.read(emergencyProvider.notifier).acknowledge();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
