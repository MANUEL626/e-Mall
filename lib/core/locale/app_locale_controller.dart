import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists UI language and notifies listeners so [MaterialApp] rebuilds.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  static const _prefsKey = 'app_locale_code';
  static const supportedLanguageCodes = <String>{'fr', 'en', 'de', 'zh'};

  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    _locale = Locale(
      code == null
          ? _systemLocaleOrDefault()
          : _normalizeSupportedCode(code),
    );
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final code = _normalizeSupportedCode(locale.languageCode);
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  static bool isSupported(String? code) {
    return code != null && supportedLanguageCodes.contains(code.toLowerCase());
  }

  static String _normalizeSupportedCode(String? code) {
    final normalized = code?.toLowerCase();
    return isSupported(normalized) ? normalized! : 'fr';
  }

  static String _systemLocaleOrDefault() {
    final systemCode = ui.PlatformDispatcher.instance.locale.languageCode;
    return isSupported(systemCode) ? systemCode.toLowerCase() : 'fr';
  }
}
