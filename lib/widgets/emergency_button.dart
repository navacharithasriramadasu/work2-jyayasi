import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Large tactical emergency button with controlled red pulse.
class EmergencyButton extends StatefulWidget {
  final VoidCallback onTrigger;
  final String label;
  final String subtitle;

  const EmergencyButton({
    super.key,
    required this.onTrigger,
    this.label = 'HOLD FOR EMERGENCY',
    this.subtitle = 'Release to confirm priority alert',
  });

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPressDown() {
    HapticFeedback.heavyImpact();
    setState(() => _isHolding = true);
  }

  void _onPressUp() {
    if (_isHolding) {
      setState(() => _isHolding = false);
      widget.onTrigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergency communication button',
      child: GestureDetector(
        onTapDown: (_) => _onPressDown(),
        onTapUp: (_) => _onPressUp(),
        onTapCancel: () => setState(() => _isHolding = false),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = _isHolding ? 1.05 : _pulseAnimation.value;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      Color(0xFF6B1A27),
                      AppColors.emergencyDark,
                      AppColors.primaryBackground,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergency
                          .withValues(alpha: _isHolding ? 0.55 : 0.30),
                      blurRadius: _isHolding ? 32 : 18,
                      spreadRadius: _isHolding ? 4 : 1,
                    ),
                  ],
                  border: Border.all(
                    color: _isHolding
                        ? AppColors.emergency
                        : const Color(0xFF8A2435),
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: AppColors.emergency,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: AppTypography.button.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: AppTypography.supporting.copyWith(
                          fontSize: 10,
                          color: AppColors.secondaryText,
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
