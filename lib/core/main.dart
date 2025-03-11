import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/progress_service.dart';
import 'services/audio_service.dart';
import 'services/tts_service.dart';
import 'services/adaptive_learning_service.dart';
import 'services/tutorial_service.dart';
import 'services/logging_service.dart';
import 'services/device_profile_service.dart';
import 'services/story_engine_service.dart';
import 'services/story_navigation_service.dart';
import 'providers/app_state_provider.dart';
import 'providers/language_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/device_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'services/navigation_service.dart';
import 'services/achievement_service.dart';
import 'services/pattern_render_service.dart';
import '../features/pattern/services/pattern_service.dart';
import '../shared/services/device_service.dart';
import '../config/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized

  // Initialize logging service first for better error tracking
  final loggingService = LoggingService();
  await loggingService.initialize();
  loggingService.info('Starting app initialization', tag: 'main');
  
  try {
    loggingService.debug('Flutter binding initialized', tag: 'main');
    
    // Load environment variables
    await dotenv.load(fileName: '.env');
    loggingService.debug('Environment variables loaded', tag: 'main');
    
    // Initialize Gemini
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      loggingService.error('Gemini API key is missing', tag: 'main');
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }
    
    Gemini.init(apiKey: apiKey);
    loggingService.debug('Gemini initialized', tag: 'main');
    
    // Initialize services
    loggingService.debug('Initializing storage service', tag: 'main');
    final storageService = StorageService();
    await storageService.initialize();
    final progressService = ProgressService(storageService);
    
    // Initialize device profile service
    loggingService.debug('Initializing device profile service', tag: 'main');
    final deviceProfileService = DeviceProfileService();
    
    // Initialize story engine service
    final storyEngineService = StoryEngineService();
    await storyEngineService.initialize(
      deviceProfileService: deviceProfileService,
      storageService: storageService,
    );
    
    // Initialize story navigation service
    final storyNavigationService = StoryNavigationService(
      storyEngine: storyEngineService,
      audioService: AudioService(),
    );
    
    // Initialize audio and TTS services
    loggingService.debug('Initializing audio services', tag: 'main');
    final audioService = AudioService();
    await audioService.initialize();
    final ttsService = TTSService();
    await ttsService.initialize();
    
    // Initialize adaptive learning service
    loggingService.debug('Initializing adaptive learning service', tag: 'main');
    final adaptiveLearningService = AdaptiveLearningService();
    await adaptiveLearningService.initialize();
    
    // Initialize tutorial service
    final tutorialService = TutorialService();
    
    // Initialize navigation service
    final navigationService = NavigationService();
    
    // Initialize achievement service
    final achievementService = AchievementService(
      storageService,
      audioService,
      navigationService.navigatorKey,
    );
    
    final patternRenderService = PatternRenderService();
    await patternRenderService.initialize(
      deviceProfileService: deviceProfileService,
      storageService: storageService,
    );
    
    // Run the app with providers
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          Provider.value(value: navigationService),
          Provider.value(value: achievementService),
          Provider.value(value: audioService),
          Provider.value(value: ttsService),
          Provider.value(value: progressService),
          ChangeNotifierProvider(create: (_) => adaptiveLearningService),
          Provider.value(value: tutorialService),
          // Add device profile providers
          Provider.value(value: deviceProfileService),
          ChangeNotifierProxyProvider<DeviceProfileService, DeviceProfileProvider>(
            create: (context) => DeviceProfileProvider(deviceProfileService),
            update: (context, service, previous) => 
              previous ?? DeviceProfileProvider(service),
          ),
          // Add story services
          Provider.value(value: storyEngineService),
          Provider.value(value: storyNavigationService),
          ChangeNotifierProvider.value(value: patternRenderService),
          ChangeNotifierProvider(create: (_) => PatternService()),
          Provider(create: (_) => DeviceService()),
        ],
        child: KenteCodeWeaverApp(
          navigatorKey: navigationService.navigatorKey,
        ),
      ),
    );
  } catch (e) {
    loggingService.error('Error during app initialization: $e', tag: 'main');
  }
}
