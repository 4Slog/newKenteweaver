import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations_delegate.dart';

class LocalizationService {
  // Supported locales
  static final List<Locale> supportedLocales = [
    const Locale('en', 'US'), // English
    const Locale('fr', 'FR'), // French
    const Locale('tw', 'GH'), // Twi (Ghana)
    const Locale('ha', 'NG'), // Hausa (Nigeria)
  ];

  // Localization delegates
  static final List<LocalizationsDelegate> localizationsDelegates = [
    const AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  // Get locale name
  static String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'tw':
        return 'Twi';
      case 'ha':
        return 'Hausa';
      default:
        return 'English';
    }
  }

  // Get locale flag emoji
  static String getLocaleFlag(Locale locale) {
    switch (locale.countryCode) {
      case 'US':
        return '🇺🇸';
      case 'FR':
        return '🇫🇷';
      case 'GH':
        return '🇬🇭';
      case 'NG':
        return '🇳🇬';
      default:
        return '🌐';
    }
  }

  // Get translated text for common UI elements
  static Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'Kente Code Weaver',
      'home': 'Home',
      'settings': 'Settings',
      'profile': 'Profile',
      'story_mode': 'Story Mode',
      'challenges': 'Challenges',
      'create_pattern': 'Create Pattern',
      'language': 'Language',
      'difficulty': 'Difficulty',
      'sound': 'Sound',
      'notifications': 'Notifications',
      'about': 'About',
      'version': 'Version',
      'continue': 'Continue',
      'previous': 'Previous',
      'next': 'Next',
      'start': 'Start',
      'finish': 'Finish',
    },
    'fr': {
      'app_title': 'Kente Code Weaver',
      'home': 'Accueil',
      'settings': 'Paramètres',
      'profile': 'Profil',
      'story_mode': 'Mode Histoire',
      'challenges': 'Défis',
      'create_pattern': 'Créer un Motif',
      'language': 'Langue',
      'difficulty': 'Difficulté',
      'sound': 'Son',
      'notifications': 'Notifications',
      'about': 'À propos',
      'version': 'Version',
      'continue': 'Continuer',
      'previous': 'Précédent',
      'next': 'Suivant',
      'start': 'Commencer',
      'finish': 'Terminer',
    },
    'tw': {
      'app_title': 'Kente Code Weaver',
      'home': 'Fie',
      'settings': 'Nhyehyɛe',
      'profile': 'Wo Ho Nsɛm',
      'story_mode': 'Anansesɛm Mode',
      'challenges': 'Nsɔhwɛ',
      'create_pattern': 'Yɛ Nhwɛso',
      'language': 'Kasa',
      'difficulty': 'Ɔhaw',
      'sound': 'Nne',
      'notifications': 'Nkra',
      'about': 'Fa Ho',
      'version': 'Version',
      'continue': 'Toa So',
      'previous': 'Kan',
      'next': 'Nea Edi Hɔ',
      'start': 'Hyɛ Ase',
      'finish': 'Wie',
    },
    'ha': {
      'app_title': 'Kente Code Weaver',
      'home': 'Gida',
      'settings': 'Saituna',
      'profile': 'Bayani',
      'story_mode': 'Yanayin Labari',
      'challenges': 'Kalubale',
      'create_pattern': 'Ƙirƙiri Zane',
      'language': 'Harshe',
      'difficulty': 'Wahala',
      'sound': 'Sauti',
      'notifications': 'Sanarwa',
      'about': 'Game da',
      'version': 'Sigar',
      'continue': 'Ci gaba',
      'previous': 'Na Baya',
      'next': 'Na Gaba',
      'start': 'Fara',
      'finish': 'Kammala',
    },
  };

  // Get translated text
  static String getTranslatedText(String key, Locale locale) {
    final languageCode = locale.languageCode;
    
    if (_translations.containsKey(languageCode) && 
        _translations[languageCode]!.containsKey(key)) {
      return _translations[languageCode]![key]!;
    }
    
    // Fallback to English
    if (_translations['en']!.containsKey(key)) {
      return _translations['en']![key]!;
    }
    
    // Return the key if no translation found
    return key;
  }
}
