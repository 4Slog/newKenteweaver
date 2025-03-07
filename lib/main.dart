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
import 'providers/app_state_provider.dart';
import 'providers/language_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  // Initialize logging service first for better error tracking
  final loggingService = LoggingService();
  await loggingService.initialize();
  loggingService.info('Starting app initialization', tag: 'main');
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    loggingService.debug('Flutter binding initialized', tag: 'main');
    
    // Load environment variables
    await dotenv.load(fileName: '.env');
    loggingService.debug('Environment variables loaded', tag: 'main');
    
    // Initialize services
    loggingService.debug('Initializing storage service', tag: 'main');
    final storageService = StorageService();
    await storageService.initialize();
    final progressService = ProgressService(storageService);
    
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

    // Initialize Gemini AI model
    loggingService.debug('Initializing Gemini AI model', tag: 'main');
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    GenerativeModel? model;
    
    if (apiKey.isNotEmpty) {
      model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
      );
      loggingService.info('Gemini AI model initialized successfully', tag: 'main');
    } else {
      loggingService.warning('No Gemini API key found, AI features will be limited', tag: 'main');
    }

    loggingService.info('All services initialized, launching app', tag: 'main');
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppStateProvider()..initialize(),
          ),
          ChangeNotifierProvider(
            create: (_) => LanguageProvider(),
          ),
          Provider.value(value: progressService),
          if (model != null) Provider.value(value: model),
          Provider.value(value: audioService),
          Provider.value(value: ttsService),
          ChangeNotifierProvider.value(value: adaptiveLearningService),
          Provider.value(value: tutorialService),
        ],
        child: const KenteCodeWeaverApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Global error handler for initialization
    loggingService.critical('Critical error during app initialization', 
      error: e, 
      stackTrace: stackTrace,
      tag: 'main',
    );
    
    // Run a minimal version of the app with error reporting
    runApp(
      MaterialApp(
        title: 'Kente Code Weaver',
        theme: ThemeData(
          primarySwatch: Colors.amber,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error Starting App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'There was a problem starting the app. Please restart and try again.',
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Attempt to restart the app
                    main();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
