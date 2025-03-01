import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('en', 'US');
  SharedPreferences? _prefs;
  
  Locale get currentLocale => _currentLocale;
  
  // List of supported languages
  final List<Map<String, dynamic>> supportedLanguages = [
    {'code': 'en', 'country': 'US', 'name': 'English'},
    {'code': 'fr', 'country': 'FR', 'name': 'French'},
    {'code': 'tw', 'country': 'GH', 'name': 'Twi (Ghana)'},
    {'code': 'ha', 'country': 'NG', 'name': 'Hausa (Nigeria)'},
  ];
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    _prefs = await SharedPreferences.getInstance();
    final languageCode = _prefs?.getString(_languageKey) ?? 'en';
    final countryCode = _getCountryCode(languageCode);
    
    _currentLocale = Locale(languageCode, countryCode);
    notifyListeners();
  }
  
  String _getCountryCode(String languageCode) {
    final language = supportedLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => supportedLanguages[0],
    );
    
    return language['country'] as String;
  }
  
  Future<void> setLanguage(String languageCode) async {
    final countryCode = _getCountryCode(languageCode);
    _currentLocale = Locale(languageCode, countryCode);
    
    await _prefs?.setString(_languageKey, languageCode);
    notifyListeners();
  }
  
  String getLanguageName(String languageCode) {
    final language = supportedLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => supportedLanguages[0],
    );
    
    return language['name'] as String;
  }
}
