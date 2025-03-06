import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_tw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ha'),
    Locale('tw')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kente Code Weaver'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kente Code Weaver!'**
  String get welcomeMessage;

  /// No description provided for @runCode.
  ///
  /// In en, this message translates to:
  /// **'Run Code'**
  String get runCode;

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get toggleTheme;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @story_mode.
  ///
  /// In en, this message translates to:
  /// **'Story Mode'**
  String get story_mode;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @create_pattern.
  ///
  /// In en, this message translates to:
  /// **'Create a pattern using coding blocks'**
  String get create_pattern;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @learning_hub.
  ///
  /// In en, this message translates to:
  /// **'Learning Hub'**
  String get learning_hub;

  /// No description provided for @weaving.
  ///
  /// In en, this message translates to:
  /// **'Weaving'**
  String get weaving;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @assessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get assessment;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @app_theme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get app_theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @audio_settings.
  ///
  /// In en, this message translates to:
  /// **'Audio Settings'**
  String get audio_settings;

  /// No description provided for @sound_effects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get sound_effects;

  /// No description provided for @enable_sound_effects.
  ///
  /// In en, this message translates to:
  /// **'Enable sound effects in the app'**
  String get enable_sound_effects;

  /// No description provided for @sound_volume.
  ///
  /// In en, this message translates to:
  /// **'Sound Volume'**
  String get sound_volume;

  /// No description provided for @background_music.
  ///
  /// In en, this message translates to:
  /// **'Background Music'**
  String get background_music;

  /// No description provided for @play_background_music.
  ///
  /// In en, this message translates to:
  /// **'Play background music'**
  String get play_background_music;

  /// No description provided for @music_volume.
  ///
  /// In en, this message translates to:
  /// **'Music Volume'**
  String get music_volume;

  /// No description provided for @text_to_speech.
  ///
  /// In en, this message translates to:
  /// **'Text-to-Speech'**
  String get text_to_speech;

  /// No description provided for @read_instructions_aloud.
  ///
  /// In en, this message translates to:
  /// **'Read instructions and feedback aloud'**
  String get read_instructions_aloud;

  /// No description provided for @speech_rate.
  ///
  /// In en, this message translates to:
  /// **'Speech Rate'**
  String get speech_rate;

  /// No description provided for @slow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @learning_reminders.
  ///
  /// In en, this message translates to:
  /// **'Learning Reminders'**
  String get learning_reminders;

  /// No description provided for @receive_daily_reminders.
  ///
  /// In en, this message translates to:
  /// **'Receive daily reminders to practice'**
  String get receive_daily_reminders;

  /// No description provided for @accessibility_options.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Options'**
  String get accessibility_options;

  /// No description provided for @high_contrast_mode.
  ///
  /// In en, this message translates to:
  /// **'High Contrast Mode'**
  String get high_contrast_mode;

  /// No description provided for @increase_contrast.
  ///
  /// In en, this message translates to:
  /// **'Increase contrast for better visibility'**
  String get increase_contrast;

  /// No description provided for @text_size.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get text_size;

  /// No description provided for @default_difficulty.
  ///
  /// In en, this message translates to:
  /// **'Default Difficulty'**
  String get default_difficulty;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in;

  /// No description provided for @backup_progress.
  ///
  /// In en, this message translates to:
  /// **'Backup Progress'**
  String get backup_progress;

  /// No description provided for @save_patterns_achievements.
  ///
  /// In en, this message translates to:
  /// **'Save your patterns and achievements'**
  String get save_patterns_achievements;

  /// No description provided for @clear_app_data.
  ///
  /// In en, this message translates to:
  /// **'Clear App Data'**
  String get clear_app_data;

  /// No description provided for @reset_progress_settings.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress and settings'**
  String get reset_progress_settings;

  /// No description provided for @clear_all_data.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data?'**
  String get clear_all_data;

  /// No description provided for @clear_data_confirmation.
  ///
  /// In en, this message translates to:
  /// **'This will reset all your progress, patterns, and settings. This action cannot be undone.'**
  String get clear_data_confirmation;

  /// No description provided for @clear_data.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clear_data;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @terms_of_service.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get terms_of_service;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @open_source_licenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get open_source_licenses;

  /// No description provided for @story_progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get story_progress;

  /// No description provided for @continue_story.
  ///
  /// In en, this message translates to:
  /// **'Continue Story'**
  String get continue_story;

  /// No description provided for @start_challenge.
  ///
  /// In en, this message translates to:
  /// **'Start Challenge'**
  String get start_challenge;

  /// No description provided for @skip_for_now.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get skip_for_now;

  /// No description provided for @start_tutorial.
  ///
  /// In en, this message translates to:
  /// **'Start Tutorial'**
  String get start_tutorial;

  /// No description provided for @skip_tutorial.
  ///
  /// In en, this message translates to:
  /// **'Skip Tutorial'**
  String get skip_tutorial;

  /// No description provided for @exit_challenge.
  ///
  /// In en, this message translates to:
  /// **'Exit Challenge'**
  String get exit_challenge;

  /// No description provided for @exit_tutorial.
  ///
  /// In en, this message translates to:
  /// **'Exit Tutorial'**
  String get exit_tutorial;

  /// No description provided for @show_cultural_context.
  ///
  /// In en, this message translates to:
  /// **'Show cultural context'**
  String get show_cultural_context;

  /// No description provided for @hide_cultural_context.
  ///
  /// In en, this message translates to:
  /// **'Hide cultural context'**
  String get hide_cultural_context;

  /// No description provided for @enable_narration.
  ///
  /// In en, this message translates to:
  /// **'Enable narration'**
  String get enable_narration;

  /// No description provided for @disable_narration.
  ///
  /// In en, this message translates to:
  /// **'Disable narration'**
  String get disable_narration;

  /// No description provided for @challenge_completed.
  ///
  /// In en, this message translates to:
  /// **'Challenge completed successfully!'**
  String get challenge_completed;

  /// No description provided for @kwaku_ananse_weaving.
  ///
  /// In en, this message translates to:
  /// **'Kwaku Ananse is weaving your story...'**
  String get kwaku_ananse_weaving;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @next_step.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get next_step;

  /// No description provided for @previous_step.
  ///
  /// In en, this message translates to:
  /// **'Previous Step'**
  String get previous_step;

  /// No description provided for @complete_tutorial.
  ///
  /// In en, this message translates to:
  /// **'Complete Tutorial'**
  String get complete_tutorial;

  /// No description provided for @tutorial_completed.
  ///
  /// In en, this message translates to:
  /// **'Tutorial Completed'**
  String get tutorial_completed;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// No description provided for @show_hint.
  ///
  /// In en, this message translates to:
  /// **'Show Hint'**
  String get show_hint;

  /// No description provided for @hide_hint.
  ///
  /// In en, this message translates to:
  /// **'Hide Hint'**
  String get hide_hint;

  /// No description provided for @drag_block.
  ///
  /// In en, this message translates to:
  /// **'Drag this block'**
  String get drag_block;

  /// No description provided for @connect_blocks.
  ///
  /// In en, this message translates to:
  /// **'Connect these blocks'**
  String get connect_blocks;

  /// No description provided for @set_value.
  ///
  /// In en, this message translates to:
  /// **'Set a value'**
  String get set_value;

  /// No description provided for @run_pattern.
  ///
  /// In en, this message translates to:
  /// **'Run your pattern'**
  String get run_pattern;

  /// No description provided for @well_done.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get well_done;

  /// No description provided for @try_next_step.
  ///
  /// In en, this message translates to:
  /// **'Try the next step'**
  String get try_next_step;

  /// No description provided for @challenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challenge;

  /// No description provided for @pattern_challenge.
  ///
  /// In en, this message translates to:
  /// **'Pattern Challenge'**
  String get pattern_challenge;

  /// No description provided for @challenge_description.
  ///
  /// In en, this message translates to:
  /// **'Complete the pattern to continue the story'**
  String get challenge_description;

  /// No description provided for @submit_challenge.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit_challenge;

  /// No description provided for @retry_challenge.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry_challenge;

  /// No description provided for @skip_challenge.
  ///
  /// In en, this message translates to:
  /// **'Skip Challenge'**
  String get skip_challenge;

  /// No description provided for @challenge_failed.
  ///
  /// In en, this message translates to:
  /// **'Challenge Failed'**
  String get challenge_failed;

  /// No description provided for @pattern_creation.
  ///
  /// In en, this message translates to:
  /// **'Pattern Creation'**
  String get pattern_creation;

  /// No description provided for @block_arrangement.
  ///
  /// In en, this message translates to:
  /// **'Block Arrangement'**
  String get block_arrangement;

  /// No description provided for @pattern_prediction.
  ///
  /// In en, this message translates to:
  /// **'Pattern Prediction'**
  String get pattern_prediction;

  /// No description provided for @code_optimization.
  ///
  /// In en, this message translates to:
  /// **'Code Optimization'**
  String get code_optimization;

  /// No description provided for @debugging.
  ///
  /// In en, this message translates to:
  /// **'Debugging'**
  String get debugging;

  /// No description provided for @success_criteria.
  ///
  /// In en, this message translates to:
  /// **'Success Criteria'**
  String get success_criteria;

  /// No description provided for @required_blocks.
  ///
  /// In en, this message translates to:
  /// **'Required Blocks'**
  String get required_blocks;

  /// No description provided for @objective.
  ///
  /// In en, this message translates to:
  /// **'Objective'**
  String get objective;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @completed_stories.
  ///
  /// In en, this message translates to:
  /// **'Completed Stories'**
  String get completed_stories;

  /// No description provided for @completed_challenges.
  ///
  /// In en, this message translates to:
  /// **'Completed Challenges'**
  String get completed_challenges;

  /// No description provided for @patterns_created.
  ///
  /// In en, this message translates to:
  /// **'Patterns Created'**
  String get patterns_created;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @change_avatar.
  ///
  /// In en, this message translates to:
  /// **'Change Avatar'**
  String get change_avatar;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_changes;

  /// No description provided for @achievement_unlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get achievement_unlocked;

  /// No description provided for @new_level.
  ///
  /// In en, this message translates to:
  /// **'New Level!'**
  String get new_level;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @mastered_concepts.
  ///
  /// In en, this message translates to:
  /// **'Mastered Concepts'**
  String get mastered_concepts;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @claim_reward.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward'**
  String get claim_reward;

  /// No description provided for @reward_claimed.
  ///
  /// In en, this message translates to:
  /// **'Reward Claimed'**
  String get reward_claimed;

  /// No description provided for @cultural_context.
  ///
  /// In en, this message translates to:
  /// **'Cultural Context'**
  String get cultural_context;

  /// No description provided for @pattern_meaning.
  ///
  /// In en, this message translates to:
  /// **'Pattern Meaning'**
  String get pattern_meaning;

  /// No description provided for @color_meaning.
  ///
  /// In en, this message translates to:
  /// **'Color Meaning'**
  String get color_meaning;

  /// No description provided for @historical_context.
  ///
  /// In en, this message translates to:
  /// **'Historical Context'**
  String get historical_context;

  /// No description provided for @traditional_use.
  ///
  /// In en, this message translates to:
  /// **'Traditional Use'**
  String get traditional_use;

  /// No description provided for @kente_tradition.
  ///
  /// In en, this message translates to:
  /// **'Kente Tradition'**
  String get kente_tradition;

  /// No description provided for @learn_more.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learn_more;

  /// No description provided for @cultural_significance.
  ///
  /// In en, this message translates to:
  /// **'Cultural Significance'**
  String get cultural_significance;

  /// No description provided for @symbolism.
  ///
  /// In en, this message translates to:
  /// **'Symbolism'**
  String get symbolism;

  /// No description provided for @ghana.
  ///
  /// In en, this message translates to:
  /// **'Ghana'**
  String get ghana;

  /// No description provided for @ashanti.
  ///
  /// In en, this message translates to:
  /// **'Ashanti'**
  String get ashanti;

  /// No description provided for @west_africa.
  ///
  /// In en, this message translates to:
  /// **'West Africa'**
  String get west_africa;

  /// No description provided for @traditional_weaving.
  ///
  /// In en, this message translates to:
  /// **'Traditional Weaving'**
  String get traditional_weaving;

  /// No description provided for @modern_interpretation.
  ///
  /// In en, this message translates to:
  /// **'Modern Interpretation'**
  String get modern_interpretation;

  /// No description provided for @dame_dame_pattern.
  ///
  /// In en, this message translates to:
  /// **'Dame-Dame Pattern'**
  String get dame_dame_pattern;

  /// No description provided for @dame_dame_description.
  ///
  /// In en, this message translates to:
  /// **'The checkerboard pattern represents duality in Akan philosophy'**
  String get dame_dame_description;

  /// No description provided for @nkyinkyim_pattern.
  ///
  /// In en, this message translates to:
  /// **'Nkyinkyim Pattern'**
  String get nkyinkyim_pattern;

  /// No description provided for @nkyinkyim_description.
  ///
  /// In en, this message translates to:
  /// **'The zigzag pattern symbolizes life\'s journey and adaptability'**
  String get nkyinkyim_description;

  /// No description provided for @babadua_pattern.
  ///
  /// In en, this message translates to:
  /// **'Babadua Pattern'**
  String get babadua_pattern;

  /// No description provided for @babadua_description.
  ///
  /// In en, this message translates to:
  /// **'The horizontal stripes pattern represents cooperation and unity'**
  String get babadua_description;

  /// No description provided for @eban_pattern.
  ///
  /// In en, this message translates to:
  /// **'Eban Pattern'**
  String get eban_pattern;

  /// No description provided for @eban_description.
  ///
  /// In en, this message translates to:
  /// **'The square pattern symbolizes security and love'**
  String get eban_description;

  /// No description provided for @obaakofo_pattern.
  ///
  /// In en, this message translates to:
  /// **'Obaakofo Pattern'**
  String get obaakofo_pattern;

  /// No description provided for @obaakofo_description.
  ///
  /// In en, this message translates to:
  /// **'The diamond pattern represents leadership and excellence'**
  String get obaakofo_description;

  /// No description provided for @kubi_pattern.
  ///
  /// In en, this message translates to:
  /// **'Kubi Pattern'**
  String get kubi_pattern;

  /// No description provided for @kubi_description.
  ///
  /// In en, this message translates to:
  /// **'The vertical stripes pattern symbolizes strength and power'**
  String get kubi_description;

  /// No description provided for @black_thread.
  ///
  /// In en, this message translates to:
  /// **'Black Thread'**
  String get black_thread;

  /// No description provided for @black_meaning.
  ///
  /// In en, this message translates to:
  /// **'Maturity, spiritual energy, and connection to ancestors'**
  String get black_meaning;

  /// No description provided for @gold_thread.
  ///
  /// In en, this message translates to:
  /// **'Gold Thread'**
  String get gold_thread;

  /// No description provided for @gold_meaning.
  ///
  /// In en, this message translates to:
  /// **'Royalty, wealth, and high status'**
  String get gold_meaning;

  /// No description provided for @red_thread.
  ///
  /// In en, this message translates to:
  /// **'Red Thread'**
  String get red_thread;

  /// No description provided for @red_meaning.
  ///
  /// In en, this message translates to:
  /// **'Political strength, sacrificial rites, and blood ties'**
  String get red_meaning;

  /// No description provided for @blue_thread.
  ///
  /// In en, this message translates to:
  /// **'Blue Thread'**
  String get blue_thread;

  /// No description provided for @blue_meaning.
  ///
  /// In en, this message translates to:
  /// **'Peace, harmony, and love'**
  String get blue_meaning;

  /// No description provided for @green_thread.
  ///
  /// In en, this message translates to:
  /// **'Green Thread'**
  String get green_thread;

  /// No description provided for @green_meaning.
  ///
  /// In en, this message translates to:
  /// **'Growth, renewal, and fertility'**
  String get green_meaning;

  /// No description provided for @error_loading.
  ///
  /// In en, this message translates to:
  /// **'Error loading content'**
  String get error_loading;

  /// No description provided for @error_saving.
  ///
  /// In en, this message translates to:
  /// **'Error saving content'**
  String get error_saving;

  /// No description provided for @connection_error.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connection_error;

  /// No description provided for @try_again_later.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get try_again_later;

  /// No description provided for @invalid_input.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get invalid_input;

  /// No description provided for @required_field.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get required_field;

  /// No description provided for @no_blocks_added.
  ///
  /// In en, this message translates to:
  /// **'No Blocks Added'**
  String get no_blocks_added;

  /// No description provided for @add_blocks_message.
  ///
  /// In en, this message translates to:
  /// **'Please add some blocks to generate a pattern'**
  String get add_blocks_message;

  /// No description provided for @missing_pattern_elements.
  ///
  /// In en, this message translates to:
  /// **'Missing Pattern Elements'**
  String get missing_pattern_elements;

  /// No description provided for @add_pattern_color_message.
  ///
  /// In en, this message translates to:
  /// **'Add at least one pattern or color block to create a design'**
  String get add_pattern_color_message;

  /// No description provided for @sign_in_future_update.
  ///
  /// In en, this message translates to:
  /// **'Sign-in will be available in a future update'**
  String get sign_in_future_update;

  /// No description provided for @backup_future_update.
  ///
  /// In en, this message translates to:
  /// **'Backup feature will be available in a future update'**
  String get backup_future_update;

  /// No description provided for @terms_future_update.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service will be available in a future update'**
  String get terms_future_update;

  /// No description provided for @privacy_future_update.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy will be available in a future update'**
  String get privacy_future_update;

  /// No description provided for @all_data_cleared.
  ///
  /// In en, this message translates to:
  /// **'All data has been cleared'**
  String get all_data_cleared;

  /// No description provided for @close_button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close_button;

  /// No description provided for @back_button.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get back_button;

  /// No description provided for @next_button.
  ///
  /// In en, this message translates to:
  /// **'Go to next'**
  String get next_button;

  /// No description provided for @play_button.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play_button;

  /// No description provided for @pause_button.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause_button;

  /// No description provided for @volume_up.
  ///
  /// In en, this message translates to:
  /// **'Increase volume'**
  String get volume_up;

  /// No description provided for @volume_down.
  ///
  /// In en, this message translates to:
  /// **'Decrease volume'**
  String get volume_down;

  /// No description provided for @toggle_sound.
  ///
  /// In en, this message translates to:
  /// **'Toggle sound'**
  String get toggle_sound;

  /// No description provided for @toggle_music.
  ///
  /// In en, this message translates to:
  /// **'Toggle music'**
  String get toggle_music;

  /// No description provided for @toggle_narration.
  ///
  /// In en, this message translates to:
  /// **'Toggle narration'**
  String get toggle_narration;

  /// No description provided for @toggle_high_contrast.
  ///
  /// In en, this message translates to:
  /// **'Toggle high contrast mode'**
  String get toggle_high_contrast;

  /// No description provided for @increase_text_size.
  ///
  /// In en, this message translates to:
  /// **'Increase text size'**
  String get increase_text_size;

  /// No description provided for @decrease_text_size.
  ///
  /// In en, this message translates to:
  /// **'Decrease text size'**
  String get decrease_text_size;

  /// No description provided for @drag_block_here.
  ///
  /// In en, this message translates to:
  /// **'Drag block here'**
  String get drag_block_here;

  /// No description provided for @connect_to_this_block.
  ///
  /// In en, this message translates to:
  /// **'Connect to this block'**
  String get connect_to_this_block;

  /// No description provided for @pattern_preview.
  ///
  /// In en, this message translates to:
  /// **'Pattern preview'**
  String get pattern_preview;

  /// No description provided for @color_selector.
  ///
  /// In en, this message translates to:
  /// **'Color selector'**
  String get color_selector;

  /// No description provided for @difficulty_selector.
  ///
  /// In en, this message translates to:
  /// **'Difficulty selector'**
  String get difficulty_selector;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @basic_description.
  ///
  /// In en, this message translates to:
  /// **'Simple patterns and concepts for beginners'**
  String get basic_description;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @intermediate_description.
  ///
  /// In en, this message translates to:
  /// **'More complex patterns with loops and variables'**
  String get intermediate_description;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @advanced_description.
  ///
  /// In en, this message translates to:
  /// **'Advanced patterns with nested structures and optimization'**
  String get advanced_description;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @master_description.
  ///
  /// In en, this message translates to:
  /// **'Expert-level pattern creation and algorithm design'**
  String get master_description;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'ha', 'tw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'ha': return AppLocalizationsHa();
    case 'tw': return AppLocalizationsTw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
