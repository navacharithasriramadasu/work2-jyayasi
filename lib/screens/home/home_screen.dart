import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/communication_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/app_status_indicator.dart';
import '../../widgets/connection_card.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/message_card.dart';
import '../../widgets/push_to_talk_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

/// The central operational command screen for iTantra Voice Transceiver.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionProvider);
    final languages = ref.watch(languageProvider);
    final communication = ref.watch(communicationProvider);
    final latestMessage = ref.watch(latestMessageProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.cell_tower,
                color: AppColors.primaryAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppConstants.appName,
                    style: AppTypography.screenTitle.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppConstants.appSubTitle.toUpperCase(),
                    style: AppTypography.supporting.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AppColors.primaryAccent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Radio status indicator in app bar
          AppStatusIndicator(
            status: connection.status,
            showPulse: connection.isConnected,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.secondaryText),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Heading & Offline Tag
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to communicate',
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Offline AI • Low-bandwidth',
                          style: AppTypography.supporting.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusChip(
                    label: 'OFFLINE AI',
                    color: AppColors.secondaryAccent,
                    icon: Icons.offline_bolt,
                    isGlowing: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Connection Card (Connected to iTantra-Rescue-01)
              ConnectionCard(
                status: connection.status,
                device: connection.connectedDevice,
                onTap: () => context.push('/connect'),
              ),
              const SizedBox(height: 14),

              // 2. Language Selector (Your Language: English ⇄ Receiver: Telugu)
              LanguageSelector(
                senderLanguage: languages.senderLanguage,
                receiverLanguage: languages.receiverLanguage,
                onSwap: () {
                  ref.read(languageProvider.notifier).swapLanguages();
                },
                onOpenLanguageSelect: () => context.push('/languages'),
              ),
              const SizedBox(height: 24),

              // 3. MAIN ACTION: Large Circular Push-To-Talk Button
              Center(
                child: Column(
                  children: [
                    PushToTalkButton(
                      state: communication.state,
                      soundLevel: communication.soundLevel,
                      isEnabled: connection.isConnected,
                      onHoldStart: () {
                        ref.read(communicationProvider.notifier).startListening();
                        context.push('/communication');
                      },
                      onHoldEnd: () async {
                        await ref.read(communicationProvider.notifier).stopListeningAndProcess();
                      },
                      onTap: () {
                        context.push('/communication');
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hold button to capture voice locally',
                      style: AppTypography.supporting.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 4. Recent Communication Section
              SectionHeader(
                title: 'Recent Transmission',
                trailing: InkWell(
                  onTap: () => context.push('/history'),
                  child: Text(
                    'VIEW ALL',
                    style: AppTypography.supportingSecondary.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              if (latestMessage != null)
                MessageCard(
                  message: latestMessage,
                  onReplay: !latestMessage.isSentByMe
                      ? () {
                          ref
                              .read(communicationProvider.notifier)
                              .speakIncomingMessage(latestMessage.text);
                        }
                      : null,
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'No recent transmissions',
                      style: AppTypography.supporting,
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
