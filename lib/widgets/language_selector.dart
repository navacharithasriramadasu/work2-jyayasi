import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/language_model.dart';

/// Interactive dual-language selector widget.
class LanguageSelector extends StatelessWidget {
  final LanguageModel senderLanguage;
  final LanguageModel receiverLanguage;
  final VoidCallback onSwap;
  final VoidCallback onOpenLanguageSelect;

  const LanguageSelector({
    super.key,
    required this.senderLanguage,
    required this.receiverLanguage,
    required this.onSwap,
    required this.onOpenLanguageSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Your Language (Source)
          Expanded(
            child: InkWell(
              onTap: onOpenLanguageSelect,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR LANGUAGE',
                      style: AppTypography.supporting.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            senderLanguage.englishName,
                            style: AppTypography.button.copyWith(
                              color: AppColors.primaryAccent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '(${senderLanguage.nativeName})',
                            style: AppTypography.supporting.copyWith(
                              color: AppColors.secondaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Swap Icon Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSwap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.elevatedSurface,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: AppColors.primaryAccent,
                  size: 20,
                ),
              ),
            ),
          ),

          // Receiver Language (Target)
          Expanded(
            child: InkWell(
              onTap: onOpenLanguageSelect,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RECEIVER LANGUAGE',
                      style: AppTypography.supporting.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            '(${receiverLanguage.nativeName})',
                            style: AppTypography.supporting.copyWith(
                              color: AppColors.secondaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            receiverLanguage.englishName,
                            style: AppTypography.button.copyWith(
                              color: AppColors.secondaryAccent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
