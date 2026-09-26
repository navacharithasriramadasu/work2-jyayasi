/// Language representation for on-device translation and TTS/STT.
class LanguageModel {
  final String code;
  final String nativeName;
  final String englishName;

  const LanguageModel({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageModel &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$englishName ($nativeName)';
}
