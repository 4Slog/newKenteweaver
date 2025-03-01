import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

/// A utility class for securely storing sensitive information like API keys
class SecureStorage {
  static const String _keyPrefix = 'kente_codeweaver_';
  static const String _apiKeyName = '${_keyPrefix}api_key';
  static const String _userTokenName = '${_keyPrefix}user_token';
  static const String _configName = '${_keyPrefix}secure_config';

  final FlutterSecureStorage _storage;

  // Cache for frequently accessed values to minimize secure storage reads
  final Map<String, String> _cache = {};

  // Singleton instance
  static SecureStorage? _instance;

  /// Private constructor for singleton pattern
  SecureStorage._({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Factory constructor to return the singleton instance
  factory SecureStorage() {
    _instance ??= SecureStorage._();
    return _instance!;
  }

  /// Initializes secure storage and loads API keys from .env if available
  Future<void> initialize() async {
    try {
      // Try to load environment variables
      await dotenv.load();

      // Check if API key exists in secure storage
      final hasApiKey = await hasKey(_apiKeyName);

      // If no API key in secure storage, try to get from .env
      if (!hasApiKey) {
        final apiKeyFromEnv = dotenv.env['API_KEY'];
        if (apiKeyFromEnv != null && apiKeyFromEnv.isNotEmpty) {
          await saveApiKey(apiKeyFromEnv);
        }
      }

      // Load cached values for better performance
      await _preloadCache();
    } catch (e) {
      debugPrint('Error initializing secure storage: $e');
    }
  }

  /// Preloads frequently used values into memory
  Future<void> _preloadCache() async {
    try {
      final apiKey = await _storage.read(key: _apiKeyName);
      if (apiKey != null) {
        _cache[_apiKeyName] = apiKey;
      }

      final config = await _storage.read(key: _configName);
      if (config != null) {
        _cache[_configName] = config;
      }
    } catch (e) {
      debugPrint('Error preloading secure storage cache: $e');
    }
  }

  /// Checks if a key exists in secure storage
  Future<bool> hasKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      debugPrint('Error checking key in secure storage: $e');
      return false;
    }
  }

  /// Saves the API key to secure storage
  Future<void> saveApiKey(String apiKey) async {
    try {
      await _storage.write(key: _apiKeyName, value: apiKey);
      _cache[_apiKeyName] = apiKey;
    } catch (e) {
      debugPrint('Error saving API key to secure storage: $e');
    }
  }

  /// Retrieves the API key from secure storage
  Future<String?> getApiKey() async {
    try {
      // Check cache first
      if (_cache.containsKey(_apiKeyName)) {
        return _cache[_apiKeyName];
      }

      final apiKey = await _storage.read(key: _apiKeyName);
      if (apiKey != null) {
        _cache[_apiKeyName] = apiKey;
      }
      return apiKey;
    } catch (e) {
      debugPrint('Error retrieving API key from secure storage: $e');
      return null;
    }
  }

  /// Saves the user authentication token
  Future<void> saveUserToken(String token) async {
    try {
      await _storage.write(key: _userTokenName, value: token);
    } catch (e) {
      debugPrint('Error saving user token to secure storage: $e');
    }
  }

  /// Retrieves the user authentication token
  Future<String?> getUserToken() async {
    try {
      return await _storage.read(key: _userTokenName);
    } catch (e) {
      debugPrint('Error retrieving user token from secure storage: $e');
      return null;
    }
  }

  /// Removes the user authentication token (for logout)
  Future<void> deleteUserToken() async {
    try {
      await _storage.delete(key: _userTokenName);
    } catch (e) {
      debugPrint('Error deleting user token from secure storage: $e');
    }
  }

  /// Saves a secure configuration object
  Future<void> saveSecureConfig(Map<String, dynamic> config) async {
    try {
      final configJson = jsonEncode(config);
      await _storage.write(key: _configName, value: configJson);
      _cache[_configName] = configJson;
    } catch (e) {
      debugPrint('Error saving secure config to secure storage: $e');
    }
  }

  /// Retrieves the secure configuration object
  Future<Map<String, dynamic>?> getSecureConfig() async {
    try {
      // Check cache first
      String? configJson;
      if (_cache.containsKey(_configName)) {
        configJson = _cache[_configName];
      } else {
        configJson = await _storage.read(key: _configName);
        if (configJson != null) {
          _cache[_configName] = configJson;
        }
      }

      if (configJson != null) {
        return jsonDecode(configJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error retrieving secure config from secure storage: $e');
      return null;
    }
  }

  /// Updates a specific key in the secure configuration
  Future<void> updateSecureConfigKey(String key, dynamic value) async {
    try {
      final config = await getSecureConfig() ?? {};
      config[key] = value;
      await saveSecureConfig(config);
    } catch (e) {
      debugPrint('Error updating secure config key: $e');
    }
  }

  /// Clears all secure storage (use with caution)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      _cache.clear();
    } catch (e) {
      debugPrint('Error clearing secure storage: $e');
    }
  }
}

// Extension for environment-specific handling
extension EnvironmentSecureStorage on SecureStorage {
  /// Gets an API key with environment-specific suffix
  Future<String?> getApiKeyForEnvironment(String environment) async {
    final baseKey = await getApiKey();
    if (baseKey == null) return null;

    try {
      final config = await getSecureConfig() ?? {};
      final environments = config['environments'] as Map<String, dynamic>? ?? {};

      if (environments.containsKey(environment)) {
        final envConfig = environments[environment] as Map<String, dynamic>;
        return envConfig['api_key'] as String? ?? baseKey;
      }

      return baseKey;
    } catch (e) {
      debugPrint('Error getting environment API key: $e');
      return baseKey;
    }
  }

  /// Adds a new environment configuration
  Future<void> addEnvironmentConfig(
      String environment,
      Map<String, dynamic> config
      ) async {
    try {
      final secureConfig = await getSecureConfig() ?? {};
      final environments = secureConfig['environments'] as Map<String, dynamic>? ?? {};

      environments[environment] = config;
      secureConfig['environments'] = environments;

      await saveSecureConfig(secureConfig);
    } catch (e) {
      debugPrint('Error adding environment config: $e');
    }
  }
}