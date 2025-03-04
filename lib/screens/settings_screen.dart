import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../providers/app_state_provider.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../models/pattern_difficulty.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../navigation/app_router.dart';
import '../extensions/breadcrumb_extensions.dart';
import '../l10n/messages.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _isLoading = true;
  
  // Settings state
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _highContrastEnabled = false;
  double _textScaleFactor = 1.0;
  double _soundVolume = 1.0;
  double _musicVolume = 0.5;
  PatternDifficulty _defaultDifficulty = PatternDifficulty.basic;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      final audioService = Provider.of<AudioService>(context, listen: false);
      
      setState(() {
        // Audio settings
        _soundEnabled = audioService.soundEnabled;
        _musicEnabled = audioService.musicEnabled;
        _soundVolume = audioService.soundVolume;
        _musicVolume = audioService.musicVolume;
        
        // Other settings
        _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
        
        // Theme settings from AppStateProvider
        _darkModeEnabled = appStateProvider.themeMode == ThemeMode.dark;
        _highContrastEnabled = appStateProvider.highContrastEnabled;
        _textScaleFactor = appStateProvider.textScaleFactor;
        
        // Difficulty settings
        _defaultDifficulty = appStateProvider.currentDifficulty;
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      }
    } catch (e) {
      print('Error saving setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings),
        // Add Kente pattern background to app bar
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/navigation/background_pattern.png'),
              fit: BoxFit.cover,
              opacity: 0.2,
            ),
          ),
        ),
      ),
      // Add subtle background pattern
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/navigation/background_pattern.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.95),
                    BlendMode.lighten,
                  ),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Add breadcrumb navigation
                  BreadcrumbNavigation(
                    items: [
                      context.getHomeBreadcrumb(),
                      context.getSettingsBreadcrumb(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSectionHeader(context, AppLocalizations.of(context).language, Icons.language),
                  _buildLanguageSelector(languageProvider),
                  const SizedBox(height: 16),
                  
                  _buildSectionHeader(context, AppLocalizations.of(context).theme, Icons.palette),
                  _buildThemeSelector(),
                  const SizedBox(height: 16),
                  
                  _buildSectionHeader(context, AppLocalizations.of(context).audio_settings, Icons.volume_up),
                  _buildAudioSettings(),
                  const SizedBox(height: 16),
                  
                  _buildSectionHeader(context, AppLocalizations.of(context).notifications, Icons.notifications),
                  _buildSwitchSetting(
                    'Learning Reminders',
                    'Receive daily reminders to practice',
                    _notificationsEnabled,
                    (value) {
                      setState(() {
                        _notificationsEnabled = value;
                        _saveSetting('notifications_enabled', value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSectionHeader(context, 'Accessibility', Icons.accessibility),
                  _buildAccessibilityOptions(),
                  const SizedBox(height: 16),
                  
                  _buildSectionHeader(context, 'Difficulty', Icons.trending_up),
                  _buildDifficultySelector(),
                  const SizedBox(height: 16),
                  
                  _buildSectionHeader(context, 'Account', Icons.person),
                  _buildAccountSection(),
                  const SizedBox(height: 16),
                  
                  _buildSectionHeader(context, 'About', Icons.info),
                  _buildAboutSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.kenteGold, AppTheme.kenteGold.withOpacity(0.7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(LanguageProvider languageProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...languageProvider.supportedLanguages.map((language) {
              final languageCode = language['code'] as String;
              final languageName = language['name'] as String;
              final isSelected = languageProvider.currentLocale.languageCode == languageCode;
              
              return ListTile(
                title: Text(languageName, style: TextStyle(color: Colors.black87)),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.kenteGold)
                    : null,
                onTap: () {
                  languageProvider.setLanguage(languageCode);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Theme',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildThemeOption(
                    'Light',
                    Icons.light_mode,
                    !_darkModeEnabled,
                    () async {
                      await appStateProvider.setThemeMode(ThemeMode.light);
                      setState(() {
                        _darkModeEnabled = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeOption(
                    'Dark',
                    Icons.dark_mode,
                    _darkModeEnabled,
                    () async {
                      await appStateProvider.setThemeMode(ThemeMode.dark);
                      setState(() {
                        _darkModeEnabled = true;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildThemeOption(
                    'System',
                    Icons.settings_suggest,
                    appStateProvider.themeMode == ThemeMode.system,
                    () async {
                      await appStateProvider.setThemeMode(ThemeMode.system);
                      setState(() {
                        _darkModeEnabled = Theme.of(context).brightness == Brightness.dark;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.kenteGold.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.kenteGold : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.kenteGold : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.kenteGold : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSettings() {
    final audioService = Provider.of<AudioService>(context, listen: false);
    final ttsService = Provider.of<TTSService>(context, listen: false);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Sound Effects
            SwitchListTile(
              title: Text('Sound Effects', style: TextStyle(color: Colors.black87)),
              subtitle: Text('Enable sound effects in the app', style: TextStyle(color: Colors.black54)),
              value: _soundEnabled,
              onChanged: (value) async {
                await audioService.toggleSound(value);
                setState(() {
                  _soundEnabled = value;
                });
                if (value) {
                  audioService.playSoundEffect(AudioType.confirmationTap);
                }
              },
              activeColor: AppTheme.kenteGold,
            ),
            
            // Sound Volume
            if (_soundEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.volume_down, color: Colors.black87),
                    Expanded(
                      child: Slider(
                        value: _soundVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(_soundVolume * 100).round()}%',
                        onChanged: (value) async {
                          await audioService.setSoundVolume(value);
                          setState(() {
                            _soundVolume = value;
                          });
                          audioService.playSoundEffect(AudioType.buttonTap);
                        },
                        activeColor: AppTheme.kenteGold,
                      ),
                    ),
                    Icon(Icons.volume_up, color: Colors.black87),
                  ],
                ),
              ),
            
            Divider(),
            
            // Background Music
            SwitchListTile(
              title: Text('Background Music', style: TextStyle(color: Colors.black87)),
              subtitle: Text('Play background music', style: TextStyle(color: Colors.black54)),
              value: _musicEnabled,
              onChanged: (value) async {
                await audioService.toggleMusic(value);
                setState(() {
                  _musicEnabled = value;
                });
                if (value) {
                  audioService.playMusic(AudioType.mainTheme);
                }
              },
              activeColor: AppTheme.kenteGold,
            ),
            
            // Music Volume
            if (_musicEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.volume_down, color: Colors.black87),
                    Expanded(
                      child: Slider(
                        value: _musicVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(_musicVolume * 100).round()}%',
                        onChanged: (value) async {
                          await audioService.setMusicVolume(value);
                          setState(() {
                            _musicVolume = value;
                          });
                        },
                        activeColor: AppTheme.kenteGold,
                      ),
                    ),
                    Icon(Icons.volume_up, color: Colors.black87),
                  ],
                ),
              ),
            
            Divider(),
            
            // Text-to-Speech
            SwitchListTile(
              title: Text('Text-to-Speech', style: TextStyle(color: Colors.black87)),
              subtitle: Text('Read instructions and feedback aloud', style: TextStyle(color: Colors.black54)),
              value: ttsService.ttsEnabled,
              onChanged: (value) async {
                await ttsService.toggleTTS(value);
                setState(() {});
                if (value) {
                  ttsService.speak('Text-to-speech is now enabled');
                }
              },
              activeColor: AppTheme.kenteGold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.black87)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.black54)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.kenteGold,
        ),
      ),
    );
  }

  Widget _buildAccessibilityOptions() {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final ttsService = Provider.of<TTSService>(context, listen: false);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility Options',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text('High Contrast Mode', style: TextStyle(color: Colors.black87)),
              subtitle: Text('Increase contrast for better visibility', style: TextStyle(color: Colors.black54)),
              value: _highContrastEnabled,
              onChanged: (value) async {
                await appStateProvider.setHighContrast(value);
                setState(() {
                  _highContrastEnabled = value;
                });
              },
              activeColor: AppTheme.kenteGold,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text Size',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('A', style: TextStyle(fontSize: 14, color: Colors.black87)),
                      Expanded(
                        child: Slider(
                          value: _textScaleFactor,
                          min: 0.8,
                          max: 1.5,
                          divisions: 7,
                          label: '${(_textScaleFactor * 100).round()}%',
                          onChanged: (value) async {
                            await appStateProvider.setTextScaleFactor(value);
                            setState(() {
                              _textScaleFactor = value;
                            });
                          },
                          activeColor: AppTheme.kenteGold,
                        ),
                      ),
                      Text('A', style: TextStyle(fontSize: 24, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
            
            Divider(),
            
            // TTS Settings
            SwitchListTile(
              title: Text('Text-to-Speech', style: TextStyle(color: Colors.black87)),
              subtitle: Text('Read instructions and feedback aloud', style: TextStyle(color: Colors.black54)),
              value: ttsService.ttsEnabled,
              onChanged: (value) async {
                await ttsService.toggleTTS(value);
                setState(() {});
                if (value) {
                  ttsService.speak('Text-to-speech is now enabled');
                }
              },
              activeColor: AppTheme.kenteGold,
            ),
            
            // TTS Speed
            if (ttsService.ttsEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speech Rate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Slow', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        Expanded(
                          child: Slider(
                            value: ttsService.ttsRate,
                            min: 0.2,
                            max: 1.0,
                            divisions: 8,
                            onChanged: (value) async {
                              await ttsService.setRate(value);
                              setState(() {});
                              ttsService.speak('This is the new speech rate');
                            },
                            activeColor: AppTheme.kenteGold,
                          ),
                        ),
                        Text('Fast', style: TextStyle(fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Difficulty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...PatternDifficulty.values.map((difficulty) {
              final isSelected = _defaultDifficulty == difficulty;
              
              return ListTile(
                title: Text(difficulty.displayName, style: TextStyle(color: Colors.black87)),
                subtitle: Text(difficulty.description, style: TextStyle(color: Colors.black54)),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.kenteGold)
                    : null,
                onTap: () {
                  appStateProvider.setDifficulty(difficulty);
                  setState(() {
                    _defaultDifficulty = difficulty;
                  });
                  
                  // Play sound effect
                  final audioService = Provider.of<AudioService>(context, listen: false);
                  if (audioService.soundEnabled) {
                    audioService.playSoundEffect(AudioType.confirmationTap);
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.kenteGold,
                child: Icon(Icons.person, color: Colors.black),
              ),
              title: Text('Guest User', style: TextStyle(color: Colors.black87)),
              subtitle: Text('Sign in to sync your progress', style: TextStyle(color: Colors.black54)),
              trailing: ElevatedButton(
                onPressed: () {
                  // Show sign-in options
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign-in will be available in a future update')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kenteGold,
                  foregroundColor: Colors.black,
                ),
                child: Text('Sign In'),
              ),
            ),
            Divider(color: Colors.grey.shade300),
            ListTile(
              leading: Icon(Icons.cloud_upload, color: Colors.black87),
              title: Text('Backup Progress', style: TextStyle(color: Colors.black87)),
              subtitle: Text('Save your patterns and achievements', style: TextStyle(color: Colors.black54)),
              onTap: () {
                // Implement backup functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backup feature will be available in a future update')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Clear App Data', style: TextStyle(color: Colors.black87)),
              subtitle: Text('Reset all progress and settings', style: TextStyle(color: Colors.black54)),
              onTap: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear All Data?'),
                    content: Text(
                      'This will reset all your progress, patterns, and settings. This action cannot be undone.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Implement data clearing
                          _prefs.clear();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('All data has been cleared')),
                          );
                          // Reload settings
                          _loadSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text('Clear Data'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.black87),
              title: Text('Version', style: TextStyle(color: Colors.black87)),
              subtitle: Text('1.0.0', style: TextStyle(color: Colors.black54)),
            ),
            ListTile(
              leading: Icon(Icons.description_outlined, color: Colors.black87),
              title: Text('Terms of Service', style: TextStyle(color: Colors.black87)),
              onTap: () {
                // Show terms of service
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terms of Service will be available in a future update')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined, color: Colors.black87),
              title: Text('Privacy Policy', style: TextStyle(color: Colors.black87)),
              onTap: () {
                // Show privacy policy
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Privacy Policy will be available in a future update')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.code, color: Colors.black87),
              title: Text('Open Source Licenses', style: TextStyle(color: Colors.black87)),
              onTap: () {
                // Show licenses
                showLicensePage(
                  context: context,
                  applicationName: 'Kente Code Weaver',
                  applicationVersion: '1.0.0',
                  applicationIcon: Image.asset(
                    'assets/images/navigation/background_pattern.png',
                    width: 50,
                    height: 50,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
