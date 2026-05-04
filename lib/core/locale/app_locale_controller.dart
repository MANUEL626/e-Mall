import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists UI language (fr | en) and notifies listeners so [MaterialApp] rebuilds.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  static const _prefsKey = 'app_locale_code';

  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == 'en') {
      _locale = const Locale('en');
    } else if (code == 'fr') {
      _locale = const Locale('fr');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (code != 'en' && code != 'fr') return;
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }
}
