import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

/// BuildContext uzerinden kolayca S erisimi:
///   context.l10n.loginButton  → 'Giris Yap' veya 'Sign In'
extension L10nExtension on BuildContext {
  S get l10n => S.of(this);
}
