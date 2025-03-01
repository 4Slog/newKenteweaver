import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlocklyLogic {
  static const String savedBlocksKey = "saved_blocks";

  /// **Loads the Blockly block definitions from JSON file**
  static Future<Map<String, dynamic>> getBlocklyJson() async {
    try {
      String jsonString = await rootBundle.loadString('assets/documents/blocks.json');
      return jsonDecode(jsonString);
    } catch (e) {
      print("❌ Error loading Blockly JSON: $e");
      return {}; // ✅ Return empty map on error
    }
  }

  /// **Saves Blockly workspace JSON to local storage**
  static Future<void> saveBlocklyJson(List<Map<String, dynamic>> blocks) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String jsonString = jsonEncode({"blocks": blocks});
      await prefs.setString(savedBlocksKey, jsonString);
      print("✅ Blockly workspace saved successfully!");
    } catch (e) {
      print("❌ Error saving Blockly JSON: $e");
    }
  }

  /// **Loads previously saved Blockly workspace from local storage**
  static Future<List<Map<String, dynamic>>> loadSavedBlocks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(savedBlocksKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        Map<String, dynamic> decoded = jsonDecode(jsonString);

        if (decoded.containsKey('blocks') && decoded['blocks'] is List) {
          return List<Map<String, dynamic>>.from(decoded['blocks']);
        }
      }
    } catch (e) {
      print("❌ Error loading saved Blockly workspace: $e");
    }

    return []; // ✅ Always return an empty list instead of null
  }

  /// **Converts dropped blocks into structured JSON for AI execution**
  static String generateBlocklyJson(List<Map<String, dynamic>>? droppedBlocks) {
    try {
      return jsonEncode({"blocks": droppedBlocks ?? []}); // ✅ Ensure list is never null
    } catch (e) {
      print("❌ Error generating Blockly JSON: $e");
      return jsonEncode({"blocks": []}); // ✅ Fallback to empty JSON
    }
  }
}
