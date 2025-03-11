import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PatternService extends ChangeNotifier {
  final Map<String, dynamic> _patterns = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get patterns => _patterns;

  Future<void> loadPatterns() async {
    try {
      _isLoading = true;
      notifyListeners();

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/patterns.json');
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents) as Map<String, dynamic>;
        _patterns.clear();
        _patterns.addAll(data);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> savePattern(String id, Map<String, dynamic> pattern) async {
    try {
      _patterns[id] = pattern;
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/patterns.json');
      
      await file.writeAsString(jsonEncode(_patterns));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getPattern(String id) async {
    try {
      return _patterns[id] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deletePattern(String id) async {
    try {
      _patterns.remove(id);
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/patterns.json');
      
      await file.writeAsString(jsonEncode(_patterns));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
} 