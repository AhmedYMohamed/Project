import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');

  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language_code');
      if (langCode != null && (langCode == 'ar' || langCode == 'en')) {
        _locale = Locale(langCode);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    if (!['ar', 'en'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'ar') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('ar'));
    }
  }
}
