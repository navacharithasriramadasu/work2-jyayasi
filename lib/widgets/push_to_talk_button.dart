import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/connection_model.dart';

/// Large circular tactical Push-to-Talk button.
/// Uses GestureDetector with onPanDown/onPanEnd to correctly detect hold gestures
/// without conflicting tap vs long-press events.
class PushToTalkButton extends StatefulWidget {
  final CommunicationState state;
  final double soundLevel;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback? onTap;
  final bool isEnabled;

  const PushToTalkButton({
    super.key,
    required this.state,
    this.soundLevel = 0.0,
    required this.onHoldStart,
    required this.onHoldEnd,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  State<PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<PushToTalkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressedLocally = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isListening =>
      widget.state == CommunicationState.listening || _isPressedLocally;

  bool get _isProcessing => widget.state == CommunicationState.processing;

  void _handlePressDown() {
    if (!widget.isEnabled || _isProcessing || _isPressedLocally) return;
    HapticFeedback.heavyImpact();
    setState(() => _isPressedLocally = true);
    widget.onHoldStart();
  }

  void _handlePressUp() {
    if (!_isPressedLocally) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPressedLocally = false);
    widget.onHoldEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Push to talk. Hold to speak, release to send.',
      // Use Listener (raw pointer events) to avoid tap/long-press conflicts
      child: Listener(
        onPointerDown: (_) => _handlePressDown(),
        onPointerUp: (_) => _handlePressUp(),
        onPointerCancel: (_) => _handlePressUp(),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = _isListening ? _pulseAnimation.value : 1.0;
            final double glowRadius = _isListening
                ? 28 + (widget.soundLevel * 20)
                : (_isProcessing ? 16 : 8);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Outer glowing rim
                  boxShadow: [
                    if (widget.isEnabled)
                      BoxShadow(
                        color: (_isListening
                                ? AppColors.primaryAccent
                                : (_isProcessing
                                    ? AppColors.secondaryAccent
                                    : AppColors.primaryAccent))
                            .withValues(
                                alpha: _isListening
                                    ? 0.45
                                    : (_isProcessing ? 0.3 : 0.15)),
                        blurRadius: glowRadius,
                        spreadRadius: _isListening ? 4 : 1,
                      ),
                  ],
                  gradient: widget.isEnabled
                      ? RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: _isListening
                              ? const [
                                  Color(0xFF005A75),
                                  Color(0xFF081C26),
                                ]
                              : (_isProcessing
                                  ? const [
                                      Color(0xFF0A3C42),
                                      Color(0xFF091F26),
                                    ]
                                  : const [
                                      Color(0xFF0D3242),
                                      Color(0xFF071822),
                                    ]),
                        )
                      : null,
                  color: widget.isEnabled ? null : AppColors.surface,
                  border: Border.all(
                    color: !widget.isEnabled
                        ? AppColors.disabled
                        : (_isListening
                            ? AppColors.primaryAccent
                            : (_isProcessing
                                ? AppColors.secondaryAccent
                                : AppColors.borderBright)),
                    width: _isListening ? 2.5 : 1.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status / Mic icon
                      if (_isProcessing)
                        const SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.secondaryAccent,
                            ),
                          ),
                        )
                      else
                        Icon(
                          _isListening ? Icons.graphic_eq : Icons.mic,
                          size: 46,
                          color: !widget.isEnabled
                              ? AppColors.disabled
                              : (_isListening
                                  ? AppColors.primaryAccent
                                  : AppColors.primaryText),
                        ),
                      const SizedBox(height: 12),

                      // Text Label
                      Text(
                        _isListening
                            ? 'LISTENING...'
                            : (_isProcessing
                                ? 'PROCESSING...'
                                : 'HOLD TO SPEAK'),
                        style: AppTypography.button.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: !widget.isEnabled
                              ? AppColors.disabled
                              : (_isListening
                                  ? AppColors.primaryAccent
                                  : AppColors.primaryText),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Supporting Subtitle
                      Text(
                        _isListening
                            ? 'Release to send'
                            : (_isProcessing
                                ? 'Local inference'
                                : !widget.isEnabled
                                    ? 'Not connected'
                                    : 'Hold to record'),
                        style: AppTypography.supporting.copyWith(
                          fontSize: 11,
                          color: !widget.isEnabled
                              ? AppColors.disabled
                              : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
