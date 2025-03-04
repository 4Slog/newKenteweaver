import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling persistent storage operations
class StorageService {
  /// Shared preferences instance
  late SharedPreferences _prefs;
  
  /// Whether the service is initialized
  bool _isInitialized = false;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }
  
  /// Get adaptive learning profiles from storage
  Future<Map<String, Map<String, dynamic>>> getAdaptiveProfiles() async {
    if (!_isInitialized) await initialize();
    
    final profilesJson = _prefs.getString('adaptive_profiles');
    if (profilesJson == null) return {};
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(profilesJson);
      final Map<String, Map<String, dynamic>> result = {};
      
      decoded.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          result[key] = value;
        }
      });
      
      return result;
    } catch (e) {
      debugPrint('Error decoding adaptive profiles: $e');
      return {};
    }
  }
  
  /// Save adaptive learning profiles to storage
  Future<bool> saveAdaptiveProfiles(Map<String, Map<String, dynamic>> profiles) async {
    if (!_isInitialized) await initialize();
    
    try {
      final String encoded = jsonEncode(profiles);
      return await _prefs.setString('adaptive_profiles', encoded);
    } catch (e) {
      debugPrint('Error encoding adaptive profiles: $e');
      return false;
    }
  }
  
  /// Get a specific user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (!_isInitialized) await initialize();
    
    final profilesJson = _prefs.getString('user_profiles');
    if (profilesJson == null) return null;
    
    try {
      final Map<String, dynamic> profiles = jsonDecode(profilesJson);
      return profiles[userId] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
  
  /// Save a user profile
  Future<bool> saveUserProfile(String userId, Map<String, dynamic> profile) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Get existing profiles
      final profilesJson = _prefs.getString('user_profiles');
      Map<String, dynamic> profiles = {};
      
      if (profilesJson != null) {
        profiles = jsonDecode(profilesJson);
      }
      
      // Update profile
      profiles[userId] = profile;
      
      // Save profiles
      final String encoded = jsonEncode(profiles);
      return await _prefs.setString('user_profiles', encoded);
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      return false;
    }
  }
  
  /// Read a value from storage
  Future<String?> read(String key) async {
    if (!_isInitialized) await initialize();
    return _prefs.getString(key);
  }
  
  /// Write a value to storage
  Future<bool> write(String key, String value) async {
    if (!_isInitialized) await initialize();
    return await _prefs.setString(key, value);
  }
  
  /// Remove a value from storage
  Future<bool> remove(String key) async {
    if (!_isInitialized) await initialize();
    return await _prefs.remove(key);
  }
  
  /// Clear all values from storage
  Future<bool> clear() async {
    if (!_isInitialized) await initialize();
    return await _prefs.clear();
  }
  
  /// Check if a key exists in storage
  Future<bool> containsKey(String key) async {
    if (!_isInitialized) await initialize();
    return _prefs.containsKey(key);
  }
  
  /// Get all keys in storage
  Future<Set<String>> getKeys() async {
    if (!_isInitialized) await initialize();
    return _prefs.getKeys();
  }
}
