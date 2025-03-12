import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logging_service.dart';
import '../services/storage_service.dart';

/// Button types for enhanced buttons
enum ButtonType {
  /// Primary action button
  primary,
  
  /// Secondary action button
  secondary,
  
  /// Accent action button
  accent,
  
  /// Danger action button
  danger,
  
  /// Success action button
  success,
}

/// Service for enhancing the UI with advanced features and animations
class UIEnhancementService extends ChangeNotifier {
  // Singleton pattern implementation
  static final UIEnhancementService _instance = UIEnhancementService._internal();
  factory UIEnhancementService() => _instance;
  
  final LoggingService _loggingService;
  final StorageService _storageService;
  
  // UI theme settings
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = Colors.blue;
  Color _accentColor = Colors.orange;
  double _animationSpeed = 1.0;
  bool _reduceMotion = false;
  bool _highContrastMode = false;
  double _textScaleFactor = 1.0;
  
  // Animation controllers
  final Map<String, AnimationController> _animationControllers = {};
  
  // UI enhancement features
  bool _enableAdvancedTransitions = true;
  bool _enableParallaxEffects = true;
  bool _enableContextualHelp = true;
  bool _enableVoiceGuidance = false;
  bool _enableGestureShortcuts = true;
  
  // Cached UI elements
  final Map<String, Widget> _cachedWidgets = {};
  
  UIEnhancementService._internal()
      : _loggingService = LoggingService(),
        _storageService = StorageService();
  
  /// Initialize the service
  Future<void> initialize() async {
    _loggingService.debug('Initializing UI enhancement service', tag: 'UIEnhancementService');
    await _loadSettings();
  }
  
  /// Load user settings
  Future<void> _loadSettings() async {
    try {
      final settingsJson = await _storageService.read('ui_settings');
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson);
        
        // Load theme settings
        _themeMode = _themeModeFromString(settings['themeMode'] ?? 'system');
        _primaryColor = _colorFromHex(settings['primaryColor'] ?? '#2196F3');
        _accentColor = _colorFromHex(settings['accentColor'] ?? '#FF9800');
        _animationSpeed = settings['animationSpeed'] ?? 1.0;
        _reduceMotion = settings['reduceMotion'] ?? false;
        _highContrastMode = settings['highContrastMode'] ?? false;
        _textScaleFactor = settings['textScaleFactor'] ?? 1.0;
        
        // Load enhancement features
        _enableAdvancedTransitions = settings['enableAdvancedTransitions'] ?? true;
        _enableParallaxEffects = settings['enableParallaxEffects'] ?? true;
        _enableContextualHelp = settings['enableContextualHelp'] ?? true;
        _enableVoiceGuidance = settings['enableVoiceGuidance'] ?? false;
        _enableGestureShortcuts = settings['enableGestureShortcuts'] ?? true;
      }
    } catch (e) {
      _loggingService.error('Error loading UI settings: $e', tag: 'UIEnhancementService');
    }
  }
  
  /// Save user settings
  Future<void> _saveSettings() async {
    try {
      final settings = {
        'themeMode': _themeModeToString(_themeMode),
        'primaryColor': _colorToHex(_primaryColor),
        'accentColor': _colorToHex(_accentColor),
        'animationSpeed': _animationSpeed,
        'reduceMotion': _reduceMotion,
        'highContrastMode': _highContrastMode,
        'textScaleFactor': _textScaleFactor,
        'enableAdvancedTransitions': _enableAdvancedTransitions,
        'enableParallaxEffects': _enableParallaxEffects,
        'enableContextualHelp': _enableContextualHelp,
        'enableVoiceGuidance': _enableVoiceGuidance,
        'enableGestureShortcuts': _enableGestureShortcuts,
      };
      await _storageService.write('ui_settings', jsonEncode(settings));
    } catch (e) {
      _loggingService.error('Error saving UI settings: $e', tag: 'UIEnhancementService');
    }
  }
  
  /// Convert ThemeMode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
  
  /// Convert string to ThemeMode
  ThemeMode _themeModeFromString(String modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
  
  /// Convert Color to hex string
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  /// Convert hex string to Color
  Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  
  /// Get the current theme data
  ThemeData getThemeData(bool isDark) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      primaryColor: _primaryColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: _primaryColor,
        secondary: _accentColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      textTheme: baseTheme.textTheme.apply(
        fontSizeFactor: _textScaleFactor,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _enableAdvancedTransitions
              ? CupertinoPageTransitionsBuilder()
              : FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: _enableAdvancedTransitions
              ? CupertinoPageTransitionsBuilder()
              : FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: _enableAdvancedTransitions
              ? CupertinoPageTransitionsBuilder()
              : FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
  
  /// Get the current theme mode
  ThemeMode getThemeMode() => _themeMode;
  
  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Set the primary color
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Set the accent color
  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Set the animation speed
  Future<void> setAnimationSpeed(double speed) async {
    _animationSpeed = speed.clamp(0.5, 2.0);
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle reduce motion
  Future<void> toggleReduceMotion() async {
    _reduceMotion = !_reduceMotion;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle high contrast mode
  Future<void> toggleHighContrastMode() async {
    _highContrastMode = !_highContrastMode;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Set text scale factor
  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor.clamp(0.8, 1.5);
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle advanced transitions
  Future<void> toggleAdvancedTransitions() async {
    _enableAdvancedTransitions = !_enableAdvancedTransitions;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle parallax effects
  Future<void> toggleParallaxEffects() async {
    _enableParallaxEffects = !_enableParallaxEffects;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle contextual help
  Future<void> toggleContextualHelp() async {
    _enableContextualHelp = !_enableContextualHelp;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle voice guidance
  Future<void> toggleVoiceGuidance() async {
    _enableVoiceGuidance = !_enableVoiceGuidance;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle gesture shortcuts
  Future<void> toggleGestureShortcuts() async {
    _enableGestureShortcuts = !_enableGestureShortcuts;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Get animation duration based on current settings
  Duration getAnimationDuration(Duration baseDuration) {
    if (_reduceMotion) {
      return Duration(milliseconds: 100);
    }
    
    return Duration(
      milliseconds: (baseDuration.inMilliseconds * _animationSpeed).round(),
    );
  }
  
  /// Get animation curve based on current settings
  Curve getAnimationCurve() {
    if (_reduceMotion) {
      return Curves.linear;
    }
    
    return Curves.easeInOutCubic;
  }
  
  /// Create an enhanced button with animations and accessibility features
  Widget createEnhancedButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    double? elevation,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    final effectiveBackgroundColor = backgroundColor ?? _primaryColor;
    final effectiveTextColor = textColor ?? Colors.white;
    final effectiveElevation = elevation ?? 4.0;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8.0);
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    
    return AnimatedContainer(
      duration: getAnimationDuration(const Duration(milliseconds: 200)),
      curve: getAnimationCurve(),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          elevation: isDisabled ? 0 : effectiveElevation,
          shape: RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
          ),
          padding: effectivePadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 16 * _textScaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Create an enhanced card with animations and accessibility features
  Widget createEnhancedCard({
    required Widget child,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    bool enableParallax = false,
  }) {
    final effectiveBackgroundColor = backgroundColor ?? Colors.white;
    final effectiveElevation = elevation ?? 2.0;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12.0);
    final effectivePadding = padding ?? const EdgeInsets.all(16.0);
    final effectiveMargin = margin ?? const EdgeInsets.all(8.0);
    
    Widget card = Card(
      color: effectiveBackgroundColor,
      elevation: effectiveElevation,
      shape: RoundedRectangleBorder(
        borderRadius: effectiveBorderRadius,
      ),
      margin: effectiveMargin,
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );
    
    if (enableParallax && _enableParallaxEffects && !_reduceMotion) {
      return MouseRegion(
        onHover: (event) {
          // In a real implementation, this would apply a parallax effect
          // based on the mouse position
        },
        child: card,
      );
    }
    
    return card;
  }
  
  /// Create an enhanced text field with animations and accessibility features
  Widget createEnhancedTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    FocusNode? focusNode,
    int? maxLines,
    int? maxLength,
    BorderRadius? borderRadius,
    Color? borderColor,
    Color? focusedBorderColor,
    Color? fillColor,
  }) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8.0);
    final effectiveBorderColor = borderColor ?? Colors.grey.shade400;
    final effectiveFocusedBorderColor = focusedBorderColor ?? _primaryColor;
    final effectiveFillColor = fillColor ?? Colors.grey.shade50;
    
    return AnimatedContainer(
      duration: getAnimationDuration(const Duration(milliseconds: 200)),
      curve: getAnimationCurve(),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        focusNode: focusNode,
        maxLines: maxLines ?? 1,
        maxLength: maxLength,
        style: TextStyle(fontSize: 16 * _textScaleFactor),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon),
                  onPressed: onSuffixIconPressed,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: effectiveBorderRadius,
            borderSide: BorderSide(color: effectiveBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: effectiveBorderRadius,
            borderSide: BorderSide(color: effectiveBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: effectiveBorderRadius,
            borderSide: BorderSide(color: effectiveFocusedBorderColor, width: 2),
          ),
          filled: true,
          fillColor: effectiveFillColor,
        ),
      ),
    );
  }
  
  /// Create a contextual help tooltip
  Widget createContextualHelp({
    required Widget child,
    required String helpText,
    String? title,
    IconData icon = Icons.help_outline,
    Color? iconColor,
    double iconSize = 20,
  }) {
    if (!_enableContextualHelp) {
      return child;
    }
    
    final effectiveIconColor = iconColor ?? _primaryColor;
    
    return Row(
      children: [
        Expanded(child: child),
        const SizedBox(width: 8),
        Tooltip(
          message: helpText,
          textStyle: TextStyle(
            fontSize: 14 * _textScaleFactor,
            color: Colors.white,
          ),
          child: Icon(
            icon,
            color: effectiveIconColor,
            size: iconSize,
          ),
        ),
      ],
    );
  }
  
  /// Create an enhanced list item with animations and accessibility features
  Widget createEnhancedListItem({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    bool isSelected = false,
  }) {
    final effectiveBackgroundColor = backgroundColor ?? Colors.white;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8.0);
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    final effectiveMargin = margin ?? const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0);
    
    return AnimatedContainer(
      duration: getAnimationDuration(const Duration(milliseconds: 200)),
      curve: getAnimationCurve(),
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: isSelected ? _primaryColor.withOpacity(0.1) : effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: isSelected ? _primaryColor : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveBorderRadius,
          child: Padding(
            padding: effectivePadding,
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16 * _textScaleFactor,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? _primaryColor : null,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14 * _textScaleFactor,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Get current UI settings
  Map<String, dynamic> getUISettings() {
    return {
      'themeMode': _themeModeToString(_themeMode),
      'primaryColor': _colorToHex(_primaryColor),
      'accentColor': _colorToHex(_accentColor),
      'animationSpeed': _animationSpeed,
      'reduceMotion': _reduceMotion,
      'highContrastMode': _highContrastMode,
      'textScaleFactor': _textScaleFactor,
      'enableAdvancedTransitions': _enableAdvancedTransitions,
      'enableParallaxEffects': _enableParallaxEffects,
      'enableContextualHelp': _enableContextualHelp,
      'enableVoiceGuidance': _enableVoiceGuidance,
      'enableGestureShortcuts': _enableGestureShortcuts,
    };
  }
  
  /// Reset UI settings to defaults
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _primaryColor = Colors.blue;
    _accentColor = Colors.orange;
    _animationSpeed = 1.0;
    _reduceMotion = false;
    _highContrastMode = false;
    _textScaleFactor = 1.0;
    _enableAdvancedTransitions = true;
    _enableParallaxEffects = true;
    _enableContextualHelp = true;
    _enableVoiceGuidance = false;
    _enableGestureShortcuts = true;
    
    await _saveSettings();
    notifyListeners();
  }
  
  /// Clear cached widgets
  void clearCache() {
    _cachedWidgets.clear();
  }
  
  /// Dispose resources
  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _cachedWidgets.clear();
    super.dispose();
  }
} 