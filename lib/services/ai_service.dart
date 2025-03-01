import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for AI-powered content generation and analysis
class AIService {
  static const String _baseUrl = 'https://api.example.com/v1';
  static const String _cachePrefix = 'ai_cache_';

  // Cache TTL in milliseconds (24 hours)
  static const int _cacheTtl = 24 * 60 * 60 * 1000;

  // Cache for AI responses to reduce API calls
  final Map<String, dynamic> _responseCache = {};

  // Shared preferences for caching
  final SharedPreferences _prefs;

  // API key from environment
  String? _apiKey;

  // Singleton instance
  static AIService? _instance;

  /// Private constructor
  AIService._({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  /// Factory constructor for singleton pattern
  static Future<AIService> getInstance({
    required SharedPreferences prefs,
  }) async {
    if (_instance == null) {
      _instance = AIService._(
        prefs: prefs,
      );

      // Initialize the service
      await _instance!._initialize();
    }

    return _instance!;
  }

  /// Initialize the service by loading API key and cached responses
  Future<void> _initialize() async {
    try {
      // Load API key from environment
      _apiKey = dotenv.env['GEMINI_API_KEY'];

      if (_apiKey == null) {
        debugPrint('Warning: No API key found in environment variables');
      }

      // Load cached responses
      await _loadCache();
    } catch (e) {
      debugPrint('Error initializing AIService: $e');
    }
  }

  /// Load cached responses from shared preferences
  Future<void> _loadCache() async {
    try {
      final cacheKeys = _prefs.getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();

      for (final key in cacheKeys) {
        final cachedData = _prefs.getString(key);
        if (cachedData != null) {
          try {
            final data = jsonDecode(cachedData);
            final timestamp = data['timestamp'] as int?;

            // Check if cache is still valid
            if (timestamp != null &&
                DateTime.now().millisecondsSinceEpoch - timestamp < _cacheTtl) {
              // Extract the query from the key
              final query = key.substring(_cachePrefix.length);
              _responseCache[query] = data['response'];
            } else {
              // Cache expired, remove it
              await _prefs.remove(key);
            }
          } catch (e) {
            debugPrint('Error parsing cached data: $e');
            await _prefs.remove(key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cache: $e');
    }
  }

  /// Save response to cache
  Future<void> _cacheResponse(String query, dynamic response) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'response': response,
      };

      // Add to in-memory cache
      _responseCache[query] = response;

      // Save to persistent cache
      await _prefs.setString(
        '$_cachePrefix$query',
        jsonEncode(cacheData),
      );
    } catch (e) {
      debugPrint('Error caching response: $e');
    }
  }

  /// Generate a cultural explanation for a given pattern or color
  Future<String> generateCulturalExplanation({
    required String patternType,
    required List<String> colors,
    bool useCache = true,
  }) async {
    // Build cache key
    final cacheKey = 'cultural_${patternType}_${colors.join('_')}';

    // Check cache first if enabled
    if (useCache && _responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey] as String;
    }

    // Ensure API key is available
    if (_apiKey == null) {
      await _initialize();
      if (_apiKey == null) {
        throw Exception('API key not available');
      }
    }

    try {
      // Prepare request payload
      final payload = {
        'pattern_type': patternType,
        'colors': colors,
        'detail_level': 'basic',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/cultural_explanations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final explanation = data['explanation'] as String;

        // Cache the response
        await _cacheResponse(cacheKey, explanation);

        return explanation;
      } else {
        // Handle error cases with appropriate fallbacks
        return _getFallbackExplanation(patternType, colors);
      }
    } catch (e) {
      debugPrint('Error generating cultural explanation: $e');
      return _getFallbackExplanation(patternType, colors);
    }
  }

  /// Get pattern complexity feedback
  Future<Map<String, dynamic>> analyzePatternComplexity({
    required List<Map<String, dynamic>> blocks,
    bool useCache = true,
  }) async {
    // Build cache key - use a hash of the blocks for unique identification
    final blocksJson = jsonEncode(blocks);
    final cacheKey = 'complexity_${_computeHash(blocksJson)}';

    // Check cache first if enabled
    if (useCache && _responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey] as Map<String, dynamic>;
    }

    // Ensure API key is available
    if (_apiKey == null) {
      await _initialize();
      if (_apiKey == null) {
        throw Exception('API key not available');
      }
    }

    try {
      // Prepare request payload
      final payload = {
        'blocks': blocks,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/analyze_pattern'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Cache the response
        await _cacheResponse(cacheKey, data);

        return data;
      } else {
        // Fallback to local complexity calculation
        return _calculateComplexityLocally(blocks);
      }
    } catch (e) {
      debugPrint('Error analyzing pattern complexity: $e');
      return _calculateComplexityLocally(blocks);
    }
  }

  /// Generate a cultural story related to a pattern
  Future<String> generateCulturalStory({
    required String patternType,
    required List<String> colors,
    String? theme,
    bool useCache = true,
  }) async {
    // Build cache key
    final cacheKey = 'story_${patternType}_${colors.join('_')}_${theme ?? 'general'}';

    // Check cache first if enabled
    if (useCache && _responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey] as String;
    }

    // Ensure API key is available
    if (_apiKey == null) {
      await _initialize();
      if (_apiKey == null) {
        throw Exception('API key not available');
      }
    }

    try {
      // Prepare request payload
      final payload = {
        'pattern_type': patternType,
        'colors': colors,
        'theme': theme,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/cultural_stories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final story = data['story'] as String;

        // Cache the response
        await _cacheResponse(cacheKey, story);

        return story;
      } else {
        // Handle error cases with appropriate fallbacks
        return _getFallbackStory(patternType, colors, theme);
      }
    } catch (e) {
      debugPrint('Error generating cultural story: $e');
      return _getFallbackStory(patternType, colors, theme);
    }
  }

  /// Clear the in-memory and persistent cache
  Future<void> clearCache() async {
    try {
      // Clear in-memory cache
      _responseCache.clear();

      // Clear persistent cache
      final cacheKeys = _prefs.getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();

      for (final key in cacheKeys) {
        await _prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Calculate a simple hash for caching purposes
  String _computeHash(String input) {
    // Simple hash function for caching
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = (hash + input.codeUnitAt(i) * (i + 1)) % 10000000;
    }
    return hash.toString();
  }

  /// Fallback explanation when API is unavailable
  String _getFallbackExplanation(String patternType, List<String> colors) {
    // Provide basic explanations for common patterns and colors
    String explanation = 'This pattern ';

    // Pattern explanation
    switch (patternType) {
      case 'checker':
      case 'checker_pattern':
        explanation += 'is called "Dame-Dame" and represents duality in Akan philosophy. ';
        break;
      case 'stripes_horizontal':
      case 'stripes_horizontal_pattern':
        explanation += 'is called "Babadua" and symbolizes unity and cooperation. ';
        break;
      case 'stripes_vertical':
      case 'stripes_vertical_pattern':
        explanation += 'is called "Kubi" and represents strength and masculinity. ';
        break;
      case 'zigzag':
      case 'zigzag_pattern':
        explanation += 'is called "Nkyinkyim" and represents adaptability and life\'s journey. ';
        break;
      case 'diamond':
      case 'diamond_pattern':
        explanation += 'represents wisdom and value. ';
        break;
      default:
        explanation += 'reflects traditional Kente weaving techniques. ';
    }

    // Color meanings
    if (colors.isNotEmpty) {
      explanation += 'The colors used have cultural significance: ';

      for (var i = 0; i < colors.length; i++) {
        if (i > 0) {
          explanation += i == colors.length - 1 ? ' and ' : ', ';
        }

        switch (colors[i]) {
          case 'gold':
          case 'yellow':
            explanation += 'gold represents royalty and wealth';
            break;
          case 'red':
            explanation += 'red symbolizes spiritual energy and ancestral blood';
            break;
          case 'blue':
            explanation += 'blue represents peace and harmony';
            break;
          case 'green':
            explanation += 'green symbolizes growth and renewal';
            break;
          case 'black':
            explanation += 'black represents maturity and spiritual energy';
            break;
          case 'white':
            explanation += 'white symbolizes purification and festive occasions';
            break;
          case 'purple':
            explanation += 'purple represents feminine aspects of life';
            break;
          default:
            explanation += '${colors[i]} adds to the pattern\'s visual appeal';
        }
      }
    }

    return explanation;
  }

  /// Calculate pattern complexity locally as a fallback
  Map<String, dynamic> _calculateComplexityLocally(List<Map<String, dynamic>> blocks) {
    // Basic complexity metrics
    double complexity = 0.0;
    int patternBlocks = 0;
    int colorBlocks = 0;
    int controlBlocks = 0;
    Set<String> uniqueColors = {};
    bool hasLoop = false;

    for (final block in blocks) {
      final type = block['type'] as String;

      if (type.contains('_pattern')) {
        patternBlocks++;

        // More complex patterns get higher scores
        if (['zigzag', 'diamond'].any((p) => type.contains(p))) {
          complexity += 0.3;
        } else {
          complexity += 0.1;
        }
      } else if (type.startsWith('shuttle_')) {
        colorBlocks++;

        // Track unique colors
        final color = type.split('_')[1];
        uniqueColors.add(color);
      } else if (type == 'loop_block') {
        controlBlocks++;
        hasLoop = true;

        // Loops add significant complexity
        final loopValue = int.tryParse(block['value']?.toString() ?? '1') ?? 1;
        complexity += 0.2 * loopValue;
      } else if (type == 'row_block' || type == 'column_block') {
        controlBlocks++;
        complexity += 0.1;
      }
    }

    // Adjust complexity based on color variety
    complexity += 0.1 * uniqueColors.length;

    // Cap complexity at 1.0
    complexity = complexity.clamp(0.0, 1.0);

    return {
      'complexity': complexity,
      'pattern_blocks': patternBlocks,
      'color_blocks': colorBlocks,
      'control_blocks': controlBlocks,
      'unique_colors': uniqueColors.length,
      'has_loop': hasLoop,
      'feedback': _getComplexityFeedback(complexity),
    };
  }

  /// Generate feedback based on complexity score
  String _getComplexityFeedback(double complexity) {
    if (complexity < 0.2) {
      return 'This is a basic pattern. Try adding more colors or using control blocks to make it more interesting.';
    } else if (complexity < 0.5) {
      return 'Good start! Your pattern shows some complexity. Consider adding loops for more interesting repetition.';
    } else if (complexity < 0.8) {
      return 'Great work! Your pattern shows good complexity with varied elements. Traditional weavers would approve!';
    } else {
      return 'Master level pattern! You\'ve created a complex design that demonstrates advanced understanding of Kente patterns.';
    }
  }

  /// Fallback story when API is unavailable
  String _getFallbackStory(String patternType, List<String> colors, String? theme) {
    String storyIntro = 'Long ago in a village in Ghana, ';

    // Adjust story based on pattern
    switch (patternType) {
      case 'checker':
      case 'checker_pattern':
        storyIntro += 'a young weaver named Kwame created the first Dame-Dame pattern. ';
        break;
      case 'stripes_horizontal':
      case 'stripes_horizontal_pattern':
        storyIntro += 'the village chief requested a special cloth that would symbolize unity. ';
        break;
      case 'stripes_vertical':
      case 'stripes_vertical_pattern':
        storyIntro += 'a master weaver taught his son the meaning of strength through the Kubi pattern. ';
        break;
      case 'zigzag':
      case 'zigzag_pattern':
        storyIntro += 'a weaver was inspired by the winding path through the mountains. ';
        break;
      default:
        storyIntro += 'a group of weavers gathered to create a new pattern. ';
    }

    // Add color symbolism to story
    String colorNarrative = 'The weaver chose ';
    if (colors.isEmpty) {
      colorNarrative += 'traditional colors that held special meaning.';
    } else {
      for (var i = 0; i < colors.length; i++) {
        if (i > 0) {
          colorNarrative += i == colors.length - 1 ? ' and ' : ', ';
        }

        switch (colors[i]) {
          case 'gold':
          case 'yellow':
            colorNarrative += 'gold to honor the royalty';
            break;
          case 'red':
            colorNarrative += 'red to represent the ancestors';
            break;
          case 'blue':
            colorNarrative += 'blue to bring peace';
            break;
          case 'green':
            colorNarrative += 'green to symbolize growth';
            break;
          case 'black':
            colorNarrative += 'black for wisdom';
            break;
          case 'white':
            colorNarrative += 'white for purity';
            break;
          default:
            colorNarrative += '${colors[i]} for beauty';
        }
      }
      colorNarrative += '.';
    }

    // Theme-based conclusion
    String conclusion;
    if (theme == 'celebration') {
      conclusion = 'The cloth was worn during festivals and celebrations, bringing joy to the community.';
    } else if (theme == 'wisdom') {
      conclusion = 'The pattern became known for representing wisdom and was worn by elders during important councils.';
    } else if (theme == 'strength') {
      conclusion = 'Warriors wore this pattern before battle, drawing strength from its symbolic meaning.';
    } else {
      conclusion = 'To this day, this pattern reminds weavers of their cultural heritage and connection to tradition.';
    }

    return '$storyIntro$colorNarrative $conclusion';
  }
}
