import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uygulama dil ayari provider'i
/// Varsayılan: Turkce. Kullanıcı değiştirebilir, SecureStorage ile kalici hale getirilebilir.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('tr');

  void setLocale(Locale locale) {
    state = locale;
  }

  void setTurkish() => state = const Locale('tr');
  void setEnglish() => state = const Locale('en');
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Desteklenen diller
const supportedLocales = [
  Locale('tr'),
  Locale('en'),
];
