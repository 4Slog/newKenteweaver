import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../config/routes/app_router.dart';
import '../config/theme/app_theme.dart';
import '../features/story/services/story_engine_service.dart';
import '../features/pattern/services/pattern_service.dart';
import '../shared/services/audio_service.dart';
import '../shared/services/device_service.dart';
import 'providers/language_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/device_profile_provider.dart';
import 'services/localization_service.dart';
import 'services/logging_service.dart';
import 'services/navigation_service.dart';
import 'services/achievement_service.dart';
import 'l10n/messages.dart';
import 'widgets/debug_overlay.dart';

class KenteCodeWeaverApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const KenteCodeWeaverApp({
    super.key,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final appStateProvider = Provider.of<AppStateProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final navigationService = Provider.of<NavigationService>(context);
    final achievementService = Provider.of<AchievementService>(context);
    final deviceProfileProvider = Provider.of<DeviceProfileProvider>(context);
    
    // Initialize logging service
    final loggingService = LoggingService();
    if (kDebugMode) {
      loggingService.initialize();
      loggingService.info('App started', tag: 'KenteCodeWeaverApp');
    }
    
    // Initialize settings from device profile if available
    if (!settingsProvider.isInitialized && deviceProfileProvider.hasProfile) {
      final profileSettings = deviceProfileProvider.profile!.settings;
      Future.microtask(() async {
        await settingsProvider.initialize();
        await settingsProvider.setSoundEnabled(profileSettings.soundEnabled);
        await settingsProvider.setMusicEnabled(profileSettings.musicEnabled);
        await settingsProvider.setHighContrast(profileSettings.highContrastMode);
        await settingsProvider.setTextScaleFactor(
          profileSettings.fontSize == 'small' ? 0.8 :
          profileSettings.fontSize == 'large' ? 1.2 : 1.0
        );
        languageProvider.setLanguage(profileSettings.language);
      });
    } else if (!settingsProvider.isInitialized) {
      Future.microtask(() => settingsProvider.initialize());
    }
    
    // Show loading screen while device profile is loading
    if (deviceProfileProvider.isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Show error screen if device profile failed to load
    if (deviceProfileProvider.error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Failed to load profile',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  deviceProfileProvider.error!,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    deviceProfileProvider.resetProfile();
                  },
                  child: Text('Reset Profile'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final app = MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Kente Code Weaver',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      initialRoute: AppRouter.welcome,
      onGenerateRoute: AppRouter.onGenerateRoute,
      
      // Navigation observers
      navigatorObservers: [
        RouteObserver<PageRoute>(),
        _NavigationObserver(navigationService),
      ],
      
      // Localization settings
      locale: Locale(deviceProfileProvider.profile?.settings.language ?? 'en'),
      supportedLocales: LocalizationService.supportedLocales,
      localizationsDelegates: [
        ...LocalizationService.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Text scaling based on device profile font size
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: settingsProvider.textScaleFactor,
          ),
          child: child!,
        );
      },
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

class _NavigationObserver extends NavigatorObserver {
  final NavigationService _navigationService;

  _NavigationObserver(this._navigationService);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      _navigationService.recordNavigation(route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      _navigationService.recordNavigation(newRoute!.settings.name!);
    }
  }
}
