// This file defines the messages that will be translated

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'generated/messages_all.dart';

class AppLocalizations {
  AppLocalizations(this.localeName);

  static Future<AppLocalizations> load(Locale locale) {
    final String name = locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      return AppLocalizations(localeName);
    });
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  final String localeName;

  // Core UI Elements
  String get appTitle {
    return Intl.message(
      'Kente Code Weaver',
      name: 'appTitle',
      desc: 'The title of the application',
      locale: localeName,
    );
  }

  String get welcomeMessage {
    return Intl.message(
      'Welcome to Kente Code Weaver!',
      name: 'welcomeMessage',
      desc: 'Welcome message displayed on the home screen',
      locale: localeName,
    );
  }

  String get runCode {
    return Intl.message(
      'Run Code',
      name: 'runCode',
      desc: 'Button text to run code',
      locale: localeName,
    );
  }

  String get toggleTheme {
    return Intl.message(
      'Toggle Theme',
      name: 'toggleTheme',
      desc: 'Button text to toggle theme',
      locale: localeName,
    );
  }

  String get continueText {
    return Intl.message(
      'Continue',
      name: 'continueText',
      desc: 'Button text to continue',
      locale: localeName,
    );
  }

  String get previous {
    return Intl.message(
      'Previous',
      name: 'previous',
      desc: 'Button text to go to previous',
      locale: localeName,
    );
  }

  String get next {
    return Intl.message(
      'Next',
      name: 'next',
      desc: 'Button text to go to next',
      locale: localeName,
    );
  }

  String get start {
    return Intl.message(
      'Start',
      name: 'start',
      desc: 'Button text to start',
      locale: localeName,
    );
  }

  String get finish {
    return Intl.message(
      'Finish',
      name: 'finish',
      desc: 'Button text to finish',
      locale: localeName,
    );
  }

  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: 'Button text to cancel',
      locale: localeName,
    );
  }

  String get confirm {
    return Intl.message(
      'Confirm',
      name: 'confirm',
      desc: 'Button text to confirm',
      locale: localeName,
    );
  }

  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: 'Button text to save',
      locale: localeName,
    );
  }

  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: 'Button text to delete',
      locale: localeName,
    );
  }

  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: 'Button text to edit',
      locale: localeName,
    );
  }

  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: 'Button text to close',
      locale: localeName,
    );
  }

  String get back {
    return Intl.message(
      'Back',
      name: 'back',
      desc: 'Button text to go back',
      locale: localeName,
    );
  }

  String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: 'Text shown during loading',
      locale: localeName,
    );
  }

  String get success {
    return Intl.message(
      'Success!',
      name: 'success',
      desc: 'Text shown on success',
      locale: localeName,
    );
  }

  String get error {
    return Intl.message(
      'Error',
      name: 'error',
      desc: 'Text shown on error',
      locale: localeName,
    );
  }

  String get warning {
    return Intl.message(
      'Warning',
      name: 'warning',
      desc: 'Text shown for warnings',
      locale: localeName,
    );
  }

  String get info {
    return Intl.message(
      'Information',
      name: 'info',
      desc: 'Text shown for information',
      locale: localeName,
    );
  }

  String get yes {
    return Intl.message(
      'Yes',
      name: 'yes',
      desc: 'Text for yes',
      locale: localeName,
    );
  }

  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: 'Text for no',
      locale: localeName,
    );
  }

  String get ok {
    return Intl.message(
      'OK',
      name: 'ok',
      desc: 'Text for OK',
      locale: localeName,
    );
  }

  // Navigation
  String get home {
    return Intl.message(
      'Home',
      name: 'home',
      desc: 'Navigation item for home',
      locale: localeName,
    );
  }

  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: 'Navigation item for settings',
      locale: localeName,
    );
  }

  String get profile {
    return Intl.message(
      'Profile',
      name: 'profile',
      desc: 'Navigation item for profile',
      locale: localeName,
    );
  }

  String get story_mode {
    return Intl.message(
      'Story Mode',
      name: 'story_mode',
      desc: 'Navigation item for story mode',
      locale: localeName,
    );
  }

  String get challenges {
    return Intl.message(
      'Challenges',
      name: 'challenges',
      desc: 'Navigation item for challenges',
      locale: localeName,
    );
  }

  String get create_pattern {
    return Intl.message(
      'Create Pattern',
      name: 'create_pattern',
      desc: 'Navigation item for create pattern',
      locale: localeName,
    );
  }

  String get tutorial {
    return Intl.message(
      'Tutorial',
      name: 'tutorial',
      desc: 'Navigation item for tutorial',
      locale: localeName,
    );
  }

  String get achievements {
    return Intl.message(
      'Achievements',
      name: 'achievements',
      desc: 'Navigation item for achievements',
      locale: localeName,
    );
  }

  String get learning_hub {
    return Intl.message(
      'Learning Hub',
      name: 'learning_hub',
      desc: 'Navigation item for learning hub',
      locale: localeName,
    );
  }

  String get weaving {
    return Intl.message(
      'Weaving',
      name: 'weaving',
      desc: 'Navigation item for weaving',
      locale: localeName,
    );
  }

  String get store {
    return Intl.message(
      'Store',
      name: 'store',
      desc: 'Navigation item for store',
      locale: localeName,
    );
  }

  String get rewards {
    return Intl.message(
      'Rewards',
      name: 'rewards',
      desc: 'Navigation item for rewards',
      locale: localeName,
    );
  }

  String get assessment {
    return Intl.message(
      'Assessment',
      name: 'assessment',
      desc: 'Navigation item for assessment',
      locale: localeName,
    );
  }

  String get project {
    return Intl.message(
      'Project',
      name: 'project',
      desc: 'Navigation item for project',
      locale: localeName,
    );
  }

  // Settings
  String get settings_title {
    return Intl.message(
      'Settings',
      name: 'settings_title',
      desc: 'Title for settings screen',
      locale: localeName,
    );
  }

  String get language {
    return Intl.message(
      'Language',
      name: 'language',
      desc: 'Language setting',
      locale: localeName,
    );
  }

  String get select_language {
    return Intl.message(
      'Select Language',
      name: 'select_language',
      desc: 'Label for language selection',
      locale: localeName,
    );
  }

  String get theme {
    return Intl.message(
      'Theme',
      name: 'theme',
      desc: 'Theme setting',
      locale: localeName,
    );
  }

  String get app_theme {
    return Intl.message(
      'App Theme',
      name: 'app_theme',
      desc: 'Label for app theme selection',
      locale: localeName,
    );
  }

  String get light {
    return Intl.message(
      'Light',
      name: 'light',
      desc: 'Light theme option',
      locale: localeName,
    );
  }

  String get dark {
    return Intl.message(
      'Dark',
      name: 'dark',
      desc: 'Dark theme option',
      locale: localeName,
    );
  }

  String get system {
    return Intl.message(
      'System',
      name: 'system',
      desc: 'System theme option',
      locale: localeName,
    );
  }

  String get audio_settings {
    return Intl.message(
      'Audio Settings',
      name: 'audio_settings',
      desc: 'Audio settings section',
      locale: localeName,
    );
  }

  String get sound_effects {
    return Intl.message(
      'Sound Effects',
      name: 'sound_effects',
      desc: 'Sound effects setting',
      locale: localeName,
    );
  }

  String get enable_sound_effects {
    return Intl.message(
      'Enable sound effects in the app',
      name: 'enable_sound_effects',
      desc: 'Description for sound effects setting',
      locale: localeName,
    );
  }

  String get sound_volume {
    return Intl.message(
      'Sound Volume',
      name: 'sound_volume',
      desc: 'Sound volume setting',
      locale: localeName,
    );
  }

  String get background_music {
    return Intl.message(
      'Background Music',
      name: 'background_music',
      desc: 'Background music setting',
      locale: localeName,
    );
  }

  String get play_background_music {
    return Intl.message(
      'Play background music',
      name: 'play_background_music',
      desc: 'Description for background music setting',
      locale: localeName,
    );
  }

  String get music_volume {
    return Intl.message(
      'Music Volume',
      name: 'music_volume',
      desc: 'Music volume setting',
      locale: localeName,
    );
  }

  String get text_to_speech {
    return Intl.message(
      'Text-to-Speech',
      name: 'text_to_speech',
      desc: 'Text-to-speech setting',
      locale: localeName,
    );
  }

  String get read_instructions_aloud {
    return Intl.message(
      'Read instructions and feedback aloud',
      name: 'read_instructions_aloud',
      desc: 'Description for text-to-speech setting',
      locale: localeName,
    );
  }

  String get speech_rate {
    return Intl.message(
      'Speech Rate',
      name: 'speech_rate',
      desc: 'Speech rate setting',
      locale: localeName,
    );
  }

  String get slow {
    return Intl.message(
      'Slow',
      name: 'slow',
      desc: 'Slow speech rate option',
      locale: localeName,
    );
  }

  String get fast {
    return Intl.message(
      'Fast',
      name: 'fast',
      desc: 'Fast speech rate option',
      locale: localeName,
    );
  }

  String get notifications {
    return Intl.message(
      'Notifications',
      name: 'notifications',
      desc: 'Notifications setting',
      locale: localeName,
    );
  }

  String get learning_reminders {
    return Intl.message(
      'Learning Reminders',
      name: 'learning_reminders',
      desc: 'Learning reminders setting',
      locale: localeName,
    );
  }

  String get receive_daily_reminders {
    return Intl.message(
      'Receive daily reminders to practice',
      name: 'receive_daily_reminders',
      desc: 'Description for learning reminders setting',
      locale: localeName,
    );
  }
}
