import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/language_model.dart';
import '../../../providers/language_provider.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/primary_action_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_chip.dart';

/// Language selection screen supporting 10 Indian languages with search and native scripts.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  final TextEditingController _searchController = TextEditingController();
  late LanguageModel _selectedSender;
  late LanguageModel _selectedReceiver;
  bool _isSelectingSender = true; // true = selecting source, false = selecting target
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final current = ref.read(languageProvider);
    _selectedSender = current.senderLanguage;
    _selectedReceiver = current.receiverLanguage;

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LanguageModel> get _filteredLanguages {
    if (_searchQuery.isEmpty) return AppConstants.supportedLanguages;
    return AppConstants.supportedLanguages.where((lang) {
      return lang.englishName.toLowerCase().contains(_searchQuery) ||
          lang.nativeName.toLowerCase().contains(_searchQuery) ||
          lang.code.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Communication Languages',
      showBack: true,
      body: Column(
        children: [
          // Active Pair Header Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Your Language Tab
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isSelectingSender = true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isSelectingSender
                            ? AppColors.elevatedSurface
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isSelectingSender
                              ? AppColors.primaryAccent
                              : AppColors.border,
                          width: _isSelectingSender ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR LANGUAGE',
                            style: AppTypography.supporting.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedSender.englishName,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _selectedSender.nativeName,
                            style: AppTypography.supporting,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Swap Icon
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: AppColors.primaryAccent),
                  onPressed: () {
                    setState(() {
                      final temp = _selectedSender;
                      _selectedSender = _selectedReceiver;
                      _selectedReceiver = temp;
                    });
                  },
                ),
                const SizedBox(width: 8),

                // Receiver Language Tab
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isSelectingSender = false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: !_isSelectingSender
                            ? AppColors.elevatedSurface
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_isSelectingSender
                              ? AppColors.secondaryAccent
                              : AppColors.border,
                          width: !_isSelectingSender ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECEIVER LANGUAGE',
                            style: AppTypography.supporting.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedReceiver.englishName,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.secondaryAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _selectedReceiver.nativeName,
                            style: AppTypography.supporting,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search language or script...',
                prefixIcon: const Icon(Icons.search, color: AppColors.mutedText),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SectionHeader(
              title: _isSelectingSender
                  ? 'Select Your Language (Speech-To-Text)'
                  : 'Select Receiver Language (Text-To-Speech)',
              trailing: const StatusChip(
                label: '10 INDIAN LANGUAGES',
                color: AppColors.primaryAccent,
              ),
            ),
          ),

          // Language List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _filteredLanguages.length,
              separatorBuilder: (_, _) => const Divider(
                color: AppColors.border,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final lang = _filteredLanguages[index];
                final isSelected = _isSelectingSender
                    ? _selectedSender.code == lang.code
                    : _selectedReceiver.code == lang.code;

                final activeColor = _isSelectingSender
                    ? AppColors.primaryAccent
                    : AppColors.secondaryAccent;

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (_isSelectingSender) {
                        _selectedSender = lang;
                      } else {
                        _selectedReceiver = lang;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            lang.nativeName,
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? activeColor : AppColors.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            lang.englishName,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: activeColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Bar & Save Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'AI processing runs locally on this device.',
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.secondaryAccent,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryActionButton(
                  label: 'Save Languages',
                  icon: Icons.check,
                  onPressed: () {
                    ref.read(languageProvider.notifier).setSenderLanguage(_selectedSender);
                    ref.read(languageProvider.notifier).setReceiverLanguage(_selectedReceiver);
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
