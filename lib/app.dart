import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/language_provider.dart';
import 'providers/app_state_provider.dart';
import 'services/localization_service.dart';
import 'services/logging_service.dart';
import 'l10n/messages.dart';
import 'widgets/debug_overlay.dart';

class KenteCodeWeaverApp extends StatelessWidget {
  const KenteCodeWeaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final appStateProvider = Provider.of<AppStateProvider>(context);
    
    // Initialize logging service
    final loggingService = LoggingService();
    if (kDebugMode) {
      loggingService.initialize();
      loggingService.info('App started', tag: 'KenteCodeWeaverApp');
    }
    
    final app = MaterialApp(
      title: 'Kente Code Weaver',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appStateProvider.themeMode,
      initialRoute: AppRouter.welcome,
      onGenerateRoute: AppRouter.onGenerateRoute,
      
      // Localization settings
      locale: languageProvider.currentLocale,
      supportedLocales: LocalizationService.supportedLocales,
      localizationsDelegates: LocalizationService.localizationsDelegates,
    );
    
    // Wrap with debug overlay in debug mode
    return kDebugMode
        ? DebugOverlay(
            enabled: true,
            child: app,
          )
        : app;
  }
}
