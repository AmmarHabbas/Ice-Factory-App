import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString('language_code');
    if (languageCode == 'en' || languageCode == 'ar') {
      state = Locale(languageCode!);
    }
  }

  void setLocale(Locale locale) {
    if (!['en', 'ar'].contains(locale.languageCode)) return;
    state = Locale(locale.languageCode);
    unawaited(
      SharedPreferences.getInstance().then(
        (preferences) =>
            preferences.setString('language_code', locale.languageCode),
      ),
    );
  }
}
