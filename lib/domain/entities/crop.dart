class Crop {
  final String id;
  final String nameEn;
  final String? nameSi;
  final String? nameTa;
  final bool isSupported;
  final String? iconAsset;

  const Crop({
    required this.id,
    required this.nameEn,
    this.nameSi,
    this.nameTa,
    this.isSupported = true,
    this.iconAsset,
  });

  String getLocalizedName(String languageCode) {
    if (languageCode == 'si' && nameSi != null && nameSi!.isNotEmpty) {
      return nameSi!;
    }
    if (languageCode == 'ta' && nameTa != null && nameTa!.isNotEmpty) {
      return nameTa!;
    }
    return nameEn;
  }
}
