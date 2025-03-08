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
        model: 'gemini-pro', // Add the required model parameter
        apiKey: apiKey,
      );
      loggingService.debug('Gemini AI model initialized', tag: 'main');
    } else {
      loggingService.error('Gemini API key is missing', tag: 'main');
    }
    
    // Run the app with providers
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          // Add other providers here
        ],
        child: KenteCodeWeaverApp(),
      ),
    );
  } catch (e) {
    loggingService.error('Error during app initialization: $e', tag: 'main');
  }
}