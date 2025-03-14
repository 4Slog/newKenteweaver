import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../services/logging_service.dart';
import '../services/storage_service.dart';

/// Sharing methods for patterns
enum SharingMethod {
  /// Share via email
  email,
  
  /// Share via QR code
  qrCode,
  
  /// Share via link
  link,
  
  /// Share via social media
  socialMedia,
  
  /// Export as file
  exportFile,
}

/// Service for sharing patterns with other users
class PatternSharingService extends ChangeNotifier {
  // Singleton pattern implementation
  static final PatternSharingService _instance = PatternSharingService._internal();
  factory PatternSharingService() => _instance;
  
  final LoggingService _loggingService;
  final StorageService _storageService;
  
  // Sharing history
  final List<Map<String, dynamic>> _sharingHistory = [];
  
  // Active shares
  final Map<String, Map<String, dynamic>> _activeShares = {};
  
  // Sharing settings
  bool _includeMetadata = true;
  bool _includeComments = true;
  bool _includeVersionHistory = false;
  bool _enableCollaboration = false;
  
  PatternSharingService._internal()
      : _loggingService = LoggingService(),
        _storageService = StorageService();
  
  /// Initialize the service
  Future<void> initialize() async {
    _loggingService.debug('Initializing pattern sharing service', tag: 'PatternSharingService');
    await _loadSettings();
    await _loadSharingHistory();
  }
  
  /// Load sharing settings
  Future<void> _loadSettings() async {
    try {
      final settingsJson = await _storageService.read('sharing_settings');
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson);
        _includeMetadata = settings['includeMetadata'] ?? true;
        _includeComments = settings['includeComments'] ?? true;
        _includeVersionHistory = settings['includeVersionHistory'] ?? false;
        _enableCollaboration = settings['enableCollaboration'] ?? false;
      }
    } catch (e) {
      _loggingService.error('Error loading sharing settings: $e', tag: 'PatternSharingService');
    }
  }
  
  /// Save sharing settings
  Future<void> _saveSettings() async {
    try {
      final settings = {
        'includeMetadata': _includeMetadata,
        'includeComments': _includeComments,
        'includeVersionHistory': _includeVersionHistory,
        'enableCollaboration': _enableCollaboration,
      };
      await _storageService.write('sharing_settings', jsonEncode(settings));
    } catch (e) {
      _loggingService.error('Error saving sharing settings: $e', tag: 'PatternSharingService');
    }
  }
  
  /// Load sharing history
  Future<void> _loadSharingHistory() async {
    try {
      final historyJson = await _storageService.read('sharing_history');
      if (historyJson != null) {
        final history = jsonDecode(historyJson) as List;
        _sharingHistory.clear();
        _sharingHistory.addAll(history.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      _loggingService.error('Error loading sharing history: $e', tag: 'PatternSharingService');
    }
  }
  
  /// Save sharing history
  Future<void> _saveSharingHistory() async {
    try {
      await _storageService.write('sharing_history', jsonEncode(_sharingHistory));
    } catch (e) {
      _loggingService.error('Error saving sharing history: $e', tag: 'PatternSharingService');
    }
  }
  
  /// Share a pattern using the specified method
  Future<String> sharePattern({
    required String patternId,
    required List<Block> blocks,
    required SharingMethod method,
    String? recipientEmail,
    String? message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Prepare pattern data for sharing
      final patternData = await _preparePatternData(patternId, blocks);
      
      // Generate share ID
      final shareId = _generateShareId();
      
      // Create share record
      final shareRecord = {
        'shareId': shareId,
        'patternId': patternId,
        'method': method.toString().split('.').last,
        'timestamp': DateTime.now().toIso8601String(),
        'recipientEmail': recipientEmail,
        'message': message,
        'additionalData': additionalData,
      };
      
      // Add to sharing history
      _sharingHistory.add(shareRecord);
      await _saveSharingHistory();
      
      // Add to active shares
      _activeShares[shareId] = {
        ...shareRecord,
        'patternData': patternData,
      };
      
      // Perform sharing based on method
      String shareUrl = '';
      
      switch (method) {
        case SharingMethod.email:
          shareUrl = await _shareViaEmail(shareId, patternData, recipientEmail!, message);
          break;
        case SharingMethod.qrCode:
          shareUrl = await _shareViaQRCode(shareId, patternData);
          break;
        case SharingMethod.link:
          shareUrl = await _shareViaLink(shareId, patternData);
          break;
        case SharingMethod.socialMedia:
          shareUrl = await _shareViaSocialMedia(shareId, patternData);
          break;
        case SharingMethod.exportFile:
          shareUrl = await _exportAsFile(shareId, patternData);
          break;
      }
      
      _loggingService.info('Pattern shared: $shareId', tag: 'PatternSharingService');
      return shareUrl;
    } catch (e) {
      _loggingService.error('Error sharing pattern: $e', tag: 'PatternSharingService');
      throw Exception('Failed to share pattern: $e');
    }
  }
  
  /// Prepare pattern data for sharing
  Future<Map<String, dynamic>> _preparePatternData(String patternId, List<Block> blocks) async {
    final patternData = {
      'id': patternId,
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Add optional data based on settings
    if (_includeMetadata) {
      patternData['metadata'] = {
        'creator': 'User', // In a real app, this would be the actual user
        'createdAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0', // In a real app, this would be the actual version
      };
    }
    
    if (_includeComments) {
      // In a real app, this would fetch actual comments
      patternData['comments'] = [];
    }
    
    if (_includeVersionHistory) {
      // In a real app, this would fetch actual version history
      patternData['versionHistory'] = [];
    }
    
    if (_enableCollaboration) {
      patternData['collaborationSettings'] = {
        'allowEditing': true,
        'allowComments': true,
        'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };
    }
    
    return patternData;
  }
  
  /// Generate a unique share ID
  String _generateShareId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'share_${timestamp}_$random';
  }
  
  /// Share pattern via email
  Future<String> _shareViaEmail(String shareId, Map<String, dynamic> patternData, String recipientEmail, String? message) async {
    // In a real implementation, this would send an actual email
    // For now, we'll just simulate it
    
    final shareUrl = 'https://kenteweaver.app/share/$shareId';
    
    _loggingService.info('Pattern shared via email to $recipientEmail', tag: 'PatternSharingService');
    
    return shareUrl;
  }
  
  /// Share pattern via QR code
  Future<String> _shareViaQRCode(String shareId, Map<String, dynamic> patternData) async {
    // In a real implementation, this would generate a QR code
    // For now, we'll just simulate it
    
    final shareUrl = 'https://kenteweaver.app/share/$shareId';
    
    _loggingService.info('Pattern shared via QR code', tag: 'PatternSharingService');
    
    return shareUrl;
  }
  
  /// Share pattern via link
  Future<String> _shareViaLink(String shareId, Map<String, dynamic> patternData) async {
    // In a real implementation, this would generate a shareable link
    // For now, we'll just simulate it
    
    final shareUrl = 'https://kenteweaver.app/share/$shareId';
    
    _loggingService.info('Pattern shared via link', tag: 'PatternSharingService');
    
    return shareUrl;
  }
  
  /// Share pattern via social media
  Future<String> _shareViaSocialMedia(String shareId, Map<String, dynamic> patternData) async {
    // In a real implementation, this would share to social media
    // For now, we'll just simulate it
    
    final shareUrl = 'https://kenteweaver.app/share/$shareId';
    
    _loggingService.info('Pattern shared via social media', tag: 'PatternSharingService');
    
    return shareUrl;
  }
  
  /// Export pattern as file
  Future<String> _exportAsFile(String shareId, Map<String, dynamic> patternData) async {
    // In a real implementation, this would export to a file
    // For now, we'll just simulate it
    
    final filePath = '/downloads/pattern_$shareId.json';
    
    _loggingService.info('Pattern exported as file', tag: 'PatternSharingService');
    
    return filePath;
  }
  
  /// Get a shared pattern by ID
  Future<Map<String, dynamic>?> getSharedPattern(String shareId) async {
    if (_activeShares.containsKey(shareId)) {
      return _activeShares[shareId];
    }
    
    return null;
  }
  
  /// Get sharing history
  List<Map<String, dynamic>> getSharingHistory() {
    return List.unmodifiable(_sharingHistory);
  }
  
  /// Clear sharing history
  Future<void> clearSharingHistory() async {
    _sharingHistory.clear();
    await _saveSharingHistory();
    notifyListeners();
  }
  
  /// Revoke a shared pattern
  Future<void> revokeSharedPattern(String shareId) async {
    if (_activeShares.containsKey(shareId)) {
      _activeShares.remove(shareId);
      
      // Update sharing history
      final index = _sharingHistory.indexWhere((share) => share['shareId'] == shareId);
      if (index >= 0) {
        _sharingHistory[index]['revoked'] = true;
        _sharingHistory[index]['revokedAt'] = DateTime.now().toIso8601String();
        await _saveSharingHistory();
      }
      
      _loggingService.info('Shared pattern revoked: $shareId', tag: 'PatternSharingService');
      notifyListeners();
    }
  }
  
  /// Toggle include metadata setting
  Future<void> toggleIncludeMetadata() async {
    _includeMetadata = !_includeMetadata;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle include comments setting
  Future<void> toggleIncludeComments() async {
    _includeComments = !_includeComments;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle include version history setting
  Future<void> toggleIncludeVersionHistory() async {
    _includeVersionHistory = !_includeVersionHistory;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle enable collaboration setting
  Future<void> toggleEnableCollaboration() async {
    _enableCollaboration = !_enableCollaboration;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Get current sharing settings
  Map<String, dynamic> getSharingSettings() {
    return {
      'includeMetadata': _includeMetadata,
      'includeComments': _includeComments,
      'includeVersionHistory': _includeVersionHistory,
      'enableCollaboration': _enableCollaboration,
    };
  }
} 