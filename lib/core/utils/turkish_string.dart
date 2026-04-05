/// Turkce buyuk-kucuk harf donusumu.
///
/// Dart'in standart toLowerCase/toUpperCase metodlari Turkce i/I
/// donusumunu dogru yapamaz (I->i yerine I->ı olmali).
/// Bu extension SADECE kullaniciya gorunen metin ve arama/filtreleme
/// islemleri icin kullanilir. Guvenlik fonksiyonlari (token, hash,
/// email karsilastirma) KULLANMAMALIDIR.
extension TurkishString on String {
  /// Turkce kurallara uygun kucuk harfe cevir.
  /// I -> ı, İ -> i (standart toLowerCase geri kalani halleder).
  String toTurkishLowerCase() {
    return replaceAll('\u0130', 'i') // İ -> i
        .replaceAll('I', '\u0131') // I -> ı
        .toLowerCase();
  }

  /// Turkce kurallara uygun buyuk harfe cevir.
  /// i -> İ, ı -> I (standart toUpperCase geri kalani halleder).
  String toTurkishUpperCase() {
    return replaceAll('\u0131', 'I') // ı -> I
        .replaceAll('i', '\u0130') // i -> İ
        .toUpperCase();
  }

  /// Turkce-duyarli icerir (contains) kontrolu.
  bool turkishContains(String other) {
    return toTurkishLowerCase().contains(other.toTurkishLowerCase());
  }
}
