import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import '../models/pattern_difficulty.dart';
import '../models/device_profile.dart';

/// Service for managing device-based anonymous profiles
class DeviceProfileService extends ChangeNotifier {
  static final DeviceProfileService _instance = DeviceProfileService._internal();
  factory DeviceProfileService() => _instance;
  DeviceProfileService._internal();

  /// Shared preferences instance
  late SharedPreferences _prefs;
  
  /// Device info plugin
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// Whether the service is initialized
  bool _isInitialized = false;
  
  /// Current device ID
  String? _deviceId;
  
  /// Current profile
  DeviceProfile? _currentProfile;
  
  /// Keys for storing profile data
  static const String _deviceIdKey = 'device_id';
  static const String _profileKey = 'device_profile';
  static const String _lastActiveKey = 'last_active';
  
  /// Get the current device ID
  String? get deviceId => _deviceId;
  
  /// Get whether a profile exists
  bool get hasProfile => _currentProfile != null;
  
  /// Get the current profile
  DeviceProfile? get currentProfile => _currentProfile;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _initializeDeviceId();
    await _loadProfile();
    
    _isInitialized = true;
    notifyListeners();
  }
  
  /// Initialize or retrieve the device ID
  Future<void> _initializeDeviceId() async {
    // Try to get existing device ID
    _deviceId = _prefs.getString(_deviceIdKey);
    
    if (_deviceId == null) {
      // Generate new device ID
      _deviceId = await _generateDeviceId();
      await _prefs.setString(_deviceIdKey, _deviceId!);
    }
  }
  
  /// Generate a unique device ID
  Future<String> _generateDeviceId() async {
    try {
      String deviceData = '';
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = '${androidInfo.id}_${androidInfo.model}_${androidInfo.brand}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData = '${iosInfo.identifierForVendor}_${iosInfo.model}_${iosInfo.name}';
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        deviceData = 'device_$now';
      }
      
      // Generate SHA-256 hash of device data
      final bytes = utf8.encode(deviceData);
      final hash = sha256.convert(bytes);
      return hash.toString().substring(0, 32); // Use first 32 chars of hash
    } catch (e) {
      debugPrint('Error generating device ID: $e');
      // Fallback to timestamp-based ID
      final now = DateTime.now().millisecondsSinceEpoch;
      return 'device_$now';
    }
  }
  
  /// Load the profile from storage
  Future<void> _loadProfile() async {
    if (_deviceId == null) return;
    
    try {
      final profileJson = _prefs.getString(_profileKey);
      if (profileJson != null) {
        final Map<String, dynamic> data = jsonDecode(profileJson);
        _currentProfile = DeviceProfile.fromJson(data);
      } else {
        // Initialize new profile
        _currentProfile = await _createNewProfile();
        await _saveProfile();
      }
      
      // Update last active timestamp
      await _updateLastActive();
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _currentProfile = await _createNewProfile();
      await _saveProfile();
    }
  }
  
  /// Create a new profile with default values
  Future<DeviceProfile> _createNewProfile() async {
    return DeviceProfile(
      deviceId: _deviceId!,
      createdAt: DateTime.now(),
      difficulty: PatternDifficulty.basic,
      progress: DeviceProfileProgress(
        completedLessons: [],
        completedChallenges: [],
        masteredConcepts: [],
        currentStoryId: null,
        unlockedPatterns: [],
      ),
      settings: DeviceProfileSettings(
        soundEnabled: true,
        musicEnabled: true,
        language: 'en',
        textToSpeechEnabled: true,
        highContrastMode: false,
        fontSize: 'medium',
      ),
    );
  }
  
  /// Save the current profile to storage
  Future<void> _saveProfile() async {
    if (_deviceId == null || _currentProfile == null) return;
    
    try {
      final profileJson = jsonEncode(_currentProfile!.toJson());
      await _prefs.setString(_profileKey, profileJson);
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }
  
  /// Update the last active timestamp
  Future<void> _updateLastActive() async {
    if (_deviceId == null) return;
    
    final now = DateTime.now().toIso8601String();
    await _prefs.setString(_lastActiveKey, now);
  }
  
  /// Update profile data
  Future<void> updateProfile(DeviceProfile newProfile) async {
    if (_deviceId == null) return;
    
    _currentProfile = newProfile;
    await _saveProfile();
    notifyListeners();
  }
  
  /// Update progress data
  Future<void> updateProgress(DeviceProfileProgress newProgress) async {
    if (_deviceId == null || _currentProfile == null) return;
    
    _currentProfile = _currentProfile!.copyWith(progress: newProgress);
    await _saveProfile();
    notifyListeners();
  }
  
  /// Update settings
  Future<void> updateSettings(DeviceProfileSettings newSettings) async {
    if (_deviceId == null || _currentProfile == null) return;
    
    _currentProfile = _currentProfile!.copyWith(settings: newSettings);
    await _saveProfile();
    notifyListeners();
  }
  
  /// Update difficulty level
  Future<void> updateDifficulty(PatternDifficulty newDifficulty) async {
    if (_deviceId == null || _currentProfile == null) return;
    
    _currentProfile = _currentProfile!.copyWith(difficulty: newDifficulty);
    await _saveProfile();
    notifyListeners();
  }
  
  /// Reset profile data
  Future<void> resetProfile() async {
    if (_deviceId == null) return;
    
    _currentProfile = await _createNewProfile();
    await _saveProfile();
    notifyListeners();
  }
  
  /// Get the last active timestamp
  Future<DateTime?> getLastActive() async {
    if (_deviceId == null) return null;
    
    final lastActiveStr = _prefs.getString(_lastActiveKey);
    if (lastActiveStr == null) return null;
    
    try {
      return DateTime.parse(lastActiveStr);
    } catch (e) {
      debugPrint('Error parsing last active timestamp: $e');
      return null;
    }
  }
} 