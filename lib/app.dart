import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/language_provider.dart';
import 'providers/app_state_provider.dart';
import 'services/localization_service.dart';

class KenteCodeWeaverApp extends StatelessWidget {
  const KenteCodeWeaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final appStateProvider = Provider.of<AppStateProvider>(context);
    
    return MaterialApp(
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
  }
}
