import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/progress_service.dart';
import 'services/audio_service.dart';
import 'services/tts_service.dart';
import 'providers/app_state_provider.dart';
import 'providers/language_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final progressService = ProgressService(storageService);
  
  // Initialize audio and TTS services
  final audioService = AudioService();
  await audioService.initialize();
  final ttsService = TTSService();
  await ttsService.initialize();

  // Initialize Gemini AI model
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: apiKey,
  );

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
        Provider.value(value: model),
        Provider.value(value: audioService),
        Provider.value(value: ttsService),
      ],
      child: const KenteCodeWeaverApp(),
    ),
  );
}
