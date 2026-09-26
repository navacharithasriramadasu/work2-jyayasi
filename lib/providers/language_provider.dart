import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/language_model.dart';

class LanguageStateModel {
  final LanguageModel senderLanguage;
  final LanguageModel receiverLanguage;

  const LanguageStateModel({
    required this.senderLanguage,
    required this.receiverLanguage,
  });

  String get pairLabel => '${senderLanguage.englishName} → ${receiverLanguage.englishName}';
}

class LanguageNotifier extends Notifier<LanguageStateModel> {
  @override
  LanguageStateModel build() {
    return const LanguageStateModel(
      senderLanguage: LanguageModel(
        code: 'en',
        englishName: 'English',
        nativeName: 'English',
      ),
      receiverLanguage: LanguageModel(
        code: 'te',
        englishName: 'Telugu',
        nativeName: 'తెలుగు',
      ),
    );
  }

  void setSenderLanguage(LanguageModel language) {
    state = LanguageStateModel(
      senderLanguage: language,
      receiverLanguage: state.receiverLanguage,
    );
  }

  void setReceiverLanguage(LanguageModel language) {
    state = LanguageStateModel(
      senderLanguage: state.senderLanguage,
      receiverLanguage: language,
    );
  }

  void swapLanguages() {
    state = LanguageStateModel(
      senderLanguage: state.receiverLanguage,
      receiverLanguage: state.senderLanguage,
    );
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, LanguageStateModel>(
  LanguageNotifier.new,
);

final supportedLanguagesProvider = Provider<List<LanguageModel>>((ref) {
  return AppConstants.supportedLanguages;
});
