import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/device_model.dart';
import '../../providers/communication_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_status_indicator.dart';
import '../../widgets/pipeline_step.dart';
import '../../widgets/primary_action_button.dart';
import '../../widgets/push_to_talk_button.dart';
import '../../widgets/status_chip.dart';

/// Single unified transceiver communication screen.
/// Dynamically renders Idle, Listening, Processing, MessageReady, Sending, Sent, and Receiving states.
class CommunicationScreen extends ConsumerStatefulWidget {
  const CommunicationScreen({super.key});

  @override
  ConsumerState<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends ConsumerState<CommunicationScreen>
    with TickerProviderStateMixin {
  late AnimationController _packetController;
  late Animation<double> _packetAnimation;
  late AnimationController _speakerController;
  late Animation<double> _speakerScale;

  @override
  void initState() {
    super.initState();
    _packetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _packetAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _packetController, curve: Curves.easeInOut),
    );

    _speakerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _speakerScale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _speakerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _packetController.dispose();
    _speakerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comm = ref.watch(communicationProvider);
    final conn = ref.watch(connectionProvider);
    final lang = ref.watch(languageProvider);

    // Show snackbar for any error feedback (e.g., no speech detected)
    ref.listen<CommunicationStateModel>(communicationProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFF1A2E3A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return AppScaffold(
      title: 'Walkie-Talkie',
      showBack: true,
      onBack: () {
        ref.read(communicationProvider.notifier).resetToIdle();
        context.pop();
      },
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: AppStatusIndicator(
            status: conn.status,
            showPulse: conn.isConnected,
          ),
        ),
      ],
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildCurrentStateView(comm, conn, lang),
      ),
    );
  }

  Widget _buildCurrentStateView(
    CommunicationStateModel comm,
    ConnectionStateModel conn,
    LanguageStateModel lang,
  ) {
    if (comm.isListening) {
      return _buildListeningState(comm);
    } else if (comm.isProcessing) {
      return _buildProcessingState(comm);
    } else if (comm.isMessageReady) {
      return _buildMessageReadyState(comm, conn, lang);
    } else if (comm.isSending) {
      return _buildSendingState(conn);
    } else if (comm.isSent) {
      return _buildSentState(comm, conn);
    } else if (comm.isReceiving) {
      return _buildReceivingState(comm);
    }
    // Default: State A - IDLE
    return _buildIdleState(comm, conn, lang);
  }

  // --------------------------------------------------------------------------
  // STATE A — IDLE
  // --------------------------------------------------------------------------
  Widget _buildIdleState(
    CommunicationStateModel comm,
    ConnectionStateModel conn,
    LanguageStateModel lang,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('idle_state'),
      padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Peer & Language Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.router, color: AppColors.primaryAccent, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          conn.connectedDevice?.name ?? 'COMMAND_NET (434.25 MHz)',
                          style: AppTypography.supportingSecondary.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lang.pairLabel,
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.secondaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Instructions
          Text(
            'HOLD TO SPEAK',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Press and hold to speak • Release to send',
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Large Circular PTT Button
          Center(
            child: PushToTalkButton(
              state: comm.state,
              soundLevel: comm.soundLevel,
              isEnabled: conn.isConnected,
              onHoldStart: () {
                ref.read(communicationProvider.notifier).startListening();
              },
              onHoldEnd: () async {
                await ref
                    .read(communicationProvider.notifier)
                    .stopListeningAndProcess();
              },
            ),
          ),
          const SizedBox(height: 28),

          // Direct Text Input Option (Demo & Noisy Venue Support)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.keyboard, color: AppColors.mutedText, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Or type message...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: AppTypography.bodySmall,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        ref.read(communicationProvider.notifier).prepareCustomText(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Technical Guarantee Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  conn.preferredTransport.label,
                  style: AppTypography.supportingSecondary,
                ),
                Text('•', style: AppTypography.supporting.copyWith(color: AppColors.mutedText)),
                const StatusChip(
                  label: 'LOCAL SPEECH ENGINE',
                  color: AppColors.secondaryAccent,
                  icon: Icons.memory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE B — LISTENING
  // --------------------------------------------------------------------------
  Widget _buildListeningState(CommunicationStateModel comm) {
    return Padding(
      key: const ValueKey('listening_state'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          const Spacer(),

          // Pulsing Mic Icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryAccent.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent
                          .withValues(alpha: 0.35 + (comm.soundLevel * 0.3)),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primaryAccent, width: 2.5),
                ),
                child: const Center(
                  child: Icon(Icons.mic, size: 48, color: AppColors.primaryAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Text(
            'LISTENING...',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: AppColors.primaryAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Speak naturally • Release when finished',
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Live Waveform
          _buildWaveformBars(comm.soundLevel),
          const SizedBox(height: 16),

          if (comm.interimHypothesis.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '"${comm.interimHypothesis}"',
                style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),

          const Spacer(),

          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local speech recognition',
                  style: AppTypography.supportingSecondary,
                ),
                const StatusChip(label: 'ON DEVICE', color: AppColors.secondaryAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Release/Done Button
          PrimaryActionButton(
            label: 'Finish Speaking',
            icon: Icons.check,
            onPressed: () async {
              await ref.read(communicationProvider.notifier).stopListeningAndProcess();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE C — PROCESSING
  // --------------------------------------------------------------------------
  Widget _buildProcessingState(CommunicationStateModel comm) {
    final step = comm.processingStep;

    return Padding(
      key: const ValueKey('processing_state'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROCESSING...',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: AppColors.secondaryAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Finishing your message with pause detection...',
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: 28),

          // Vertical Pipeline
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                PipelineStep(
                  state: step >= 1 ? PipelineStepState.completed : PipelineStepState.active,
                  title: 'Voice captured',
                  subtitle: 'Silence boundary detected',
                ),
                PipelineStep(
                  state: step >= 2
                      ? PipelineStepState.completed
                      : (step == 1 ? PipelineStepState.active : PipelineStepState.pending),
                  title: 'Speech recognized locally',
                  subtitle: 'On-device neural inference',
                ),
                PipelineStep(
                  state: step >= 3
                      ? PipelineStepState.completed
                      : (step == 2 ? PipelineStepState.active : PipelineStepState.pending),
                  title: 'Preparing message',
                  subtitle: 'Compressing text payload',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (comm.currentText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DETECTED TEXT',
                    style: AppTypography.supporting.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${comm.currentText}"',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          const Spacer(),

          PrimaryActionButton(
            label: 'Cancel',
            variant: ActionButtonVariant.secondary,
            onPressed: () {
              ref.read(communicationProvider.notifier).cancelListening();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE D — MESSAGE READY
  // --------------------------------------------------------------------------
  Widget _buildMessageReadyState(
    CommunicationStateModel comm,
    ConnectionStateModel conn,
    LanguageStateModel lang,
  ) {
    final text = comm.currentText.trim();
    if (text.isEmpty) {
      // No text captured — return to idle automatically
      Future.microtask(() =>
          ref.read(communicationProvider.notifier).resetToIdle());
      return const SizedBox.shrink();
    }

    return Padding(
      key: const ValueKey('ready_state'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Message Ready',
                style: AppTypography.screenTitle.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const StatusChip(
                label: 'TEXT ONLY',
                color: AppColors.secondaryAccent,
                icon: Icons.text_snippet,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Voice has been converted to text. Ready to transmit.',
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: 24),

          // Message Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"$text"',
                  style: AppTypography.screenTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.pairLabel, style: AppTypography.supportingSecondary),
                    Text(conn.preferredTransport.label, style: AppTypography.supporting),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Low bandwidth pill
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed, size: 18, color: AppColors.secondaryAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transmission payload: ~${text.length * 2} Bytes over local radio link.',
                    style: AppTypography.supporting.copyWith(color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Actions
          PrimaryActionButton(
            label: 'Send Message',
            icon: Icons.send,
            onPressed: () async {
              await ref.read(communicationProvider.notifier).sendMessage();
            },
          ),
          const SizedBox(height: 12),
          PrimaryActionButton(
            label: 'Speak Again',
            variant: ActionButtonVariant.secondary,
            icon: Icons.refresh,
            onPressed: () {
              ref.read(communicationProvider.notifier).speakAgain();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE E — SENDING
  // --------------------------------------------------------------------------
  Widget _buildSendingState(ConnectionStateModel conn) {
    return Padding(
      key: const ValueKey('sending_state'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        children: [
          const Spacer(),

          Text(
            'TRANSMITTING TEXT...',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: AppColors.primaryAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No audio is being transmitted.',
            style: AppTypography.bodySecondary.copyWith(color: AppColors.secondaryAccent),
          ),
          const SizedBox(height: 36),

          // Diagram
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildDiagNode(Icons.text_snippet, 'TEXT MESSAGE', 'On-device string', true),
                SizedBox(
                  height: 70,
                  child: AnimatedBuilder(
                    animation: _packetAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(width: 2, height: 70, color: AppColors.borderBright),
                          Positioned(
                            top: _packetAnimation.value * 50,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondaryAccent.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _buildDiagNode(
                  Icons.cell_tower,
                  'RECEIVING DEVICE',
                  conn.connectedDevice?.name ?? 'COMMAND_NET (434.25 MHz)',
                  false,
                ),
              ],
            ),
          ),

          const Spacer(),
          const StatusChip(
            label: 'AIR INTERFACE: LOW-BANDWIDTH TEXT ENCODED',
            color: AppColors.secondaryAccent,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE F — SENT
  // --------------------------------------------------------------------------
  Widget _buildSentState(CommunicationStateModel comm, ConnectionStateModel conn) {
    final text = comm.activeMessage?.text ?? comm.currentText;

    return Padding(
      key: const ValueKey('sent_state'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          const Spacer(),

          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.connected.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.connected, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.connected.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.check, color: AppColors.connected, size: 42),
          ),
          const SizedBox(height: 20),

          Text(
            'Message Sent',
            style: AppTypography.screenTitle.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.done_all, color: AppColors.connected, size: 16),
              const SizedBox(width: 6),
              Text(
                'Delivered to ${conn.connectedDevice?.name ?? 'COMMAND_NET (434.25 MHz)'}',
                style: AppTypography.supportingSecondary.copyWith(
                  color: AppColors.connected,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Message Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"$text"',
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                const StatusChip(
                  label: 'TEXT TRANSMITTED • AUDIO NOT TRANSMITTED',
                  color: AppColors.connected,
                ),
              ],
            ),
          ),

          const Spacer(),

          PrimaryActionButton(
            label: 'Send Another',
            icon: Icons.mic,
            onPressed: () {
              ref.read(communicationProvider.notifier).resetToIdle();
            },
          ),
          const SizedBox(height: 12),
          PrimaryActionButton(
            label: 'Back to Home',
            variant: ActionButtonVariant.secondary,
            icon: Icons.home,
            onPressed: () {
              ref.read(communicationProvider.notifier).resetToIdle();
              context.go('/home');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STATE G — RECEIVING / SPEAKING
  // --------------------------------------------------------------------------
  Widget _buildReceivingState(CommunicationStateModel comm) {
    final msg = comm.incomingMessage;
    final messageText = msg?.text ?? 'Location coordinates received. Unit moving to sector.';
    final isSpeaking = comm.isSpeaking || comm.isAudioPlaybackActive;

    return Padding(
      key: const ValueKey('receiving_state'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          const Spacer(),

          AnimatedBuilder(
            animation: _speakerScale,
            builder: (context, child) {
              final scale = isSpeaking ? _speakerScale.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: isSpeaking ? AppColors.secondaryAccent : AppColors.border,
                      width: 2.0,
                    ),
                    boxShadow: isSpeaking
                        ? [
                            BoxShadow(
                              color: AppColors.secondaryAccent.withValues(alpha: 0.4),
                              blurRadius: 28,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      isSpeaking ? Icons.volume_up : Icons.volume_down,
                      size: 48,
                      color: isSpeaking ? AppColors.secondaryAccent : AppColors.primaryText,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          Text(
            isSpeaking ? '🔊 SPEAKING' : 'INCOMING MESSAGE',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: isSpeaking ? AppColors.secondaryAccent : AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSpeaking ? 'Reconstructing speech on-device via TTS' : 'Converting text to speech...',
            style: AppTypography.supporting.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 24),

          // Message Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FROM: ${msg?.sender ?? "TACTICAL_PEER"}',
                      style: AppTypography.supportingSecondary.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const StatusChip(label: 'ON-DEVICE TTS', color: AppColors.secondaryAccent),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"$messageText"',
                  style: AppTypography.screenTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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
                  label: 'Replay',
                  icon: Icons.replay,
                  variant: ActionButtonVariant.primary,
                  onPressed: () {
                    ref.read(communicationProvider.notifier).speakIncomingMessage(messageText);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryActionButton(
                  label: 'Stop',
                  icon: Icons.stop,
                  variant: ActionButtonVariant.secondary,
                  onPressed: () {
                    ref.read(communicationProvider.notifier).stopSpeaking();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(communicationProvider.notifier).resetToIdle();
              },
              child: Text(
                'Dismiss to Ready',
                style: AppTypography.button.copyWith(color: AppColors.secondaryText),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDiagNode(IconData icon, String title, String subtitle, bool isActive) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? AppColors.primaryAccent : AppColors.border),
          ),
          child: Icon(
            icon,
            color: isActive ? AppColors.primaryAccent : AppColors.secondaryText,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(subtitle, style: AppTypography.supporting),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveformBars(double soundLevel) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(16, (index) {
          final normalized = (index - 8).abs();
          final mult = (8 - normalized) / 8;
          final height = (8 + (soundLevel * 32 * mult)).clamp(6.0, 40.0);
          return Container(
            width: 4,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.5 + (0.5 * mult)),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
