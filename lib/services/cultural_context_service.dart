import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/pattern_difficulty.dart';
import 'gemini_service.dart';
import 'logging_service.dart';
import 'storage_service.dart';

/// Service for providing cultural context information about Kente patterns, colors, and symbols
class CulturalContextService extends ChangeNotifier {
  final GeminiService _geminiService;
  final LoggingService _loggingService;
  final StorageService _storageService;
  
  /// Map of pattern IDs to cultural information
  Map<String, PatternCulturalInfo> _patternInfo = {};
  
  /// Map of color IDs to cultural information
  Map<String, ColorCulturalInfo> _colorInfo = {};
  
  /// Map of symbol IDs to cultural information
  Map<String, SymbolCulturalInfo> _symbolInfo = {};
  
  /// Map of region IDs to cultural information
  Map<String, RegionalInfo> _regionalInfo = {};
  
  /// Whether the service is initialized
  bool _isInitialized = false;
  
  // Singleton pattern
  static CulturalContextService? _instance;
  
  /// Private constructor to enforce singleton pattern
  CulturalContextService._({
    required GeminiService geminiService,
    required LoggingService loggingService,
    required StorageService storageService,
  }) : _geminiService = geminiService,
       _loggingService = loggingService,
       _storageService = storageService;
  
  /// Factory constructor to get the singleton instance
  factory CulturalContextService({
    required GeminiService geminiService,
    required LoggingService loggingService,
    required StorageService storageService,
  }) {
    _instance ??= CulturalContextService._(
      geminiService: geminiService,
      loggingService: loggingService,
      storageService: storageService,
    );
    return _instance!;
  }
  
  /// Get all pattern cultural information
  Map<String, PatternCulturalInfo> get patternInfo => 
      Map.unmodifiable(_patternInfo);
  
  /// Get all color cultural information
  Map<String, ColorCulturalInfo> get colorInfo => 
      Map.unmodifiable(_colorInfo);
  
  /// Get all symbol cultural information
  Map<String, SymbolCulturalInfo> get symbolInfo => 
      Map.unmodifiable(_symbolInfo);
  
  /// Get all regional cultural information
  Map<String, RegionalInfo> get regionalInfo => 
      Map.unmodifiable(_regionalInfo);
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _loggingService.info('Initializing CulturalContextService', tag: 'CulturalContextService');
    
    // Load cultural information from assets
    await _loadCulturalData();
    
    _isInitialized = true;
    _loggingService.info('CulturalContextService initialized successfully', tag: 'CulturalContextService');
  }
  
  /// Load cultural data from assets
  Future<void> _loadCulturalData() async {
    try {
      // Load pattern information
      final patternJson = await rootBundle.loadString('assets/data/patterns_cultural_info.json');
      final patternData = jsonDecode(patternJson) as Map<String, dynamic>;
      
      patternData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _patternInfo[key] = PatternCulturalInfo.fromJson(value);
        }
      });
      
      // Load color information
      final colorJson = await rootBundle.loadString('assets/data/colors_cultural_info.json');
      final colorData = jsonDecode(colorJson) as Map<String, dynamic>;
      
      colorData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _colorInfo[key] = ColorCulturalInfo.fromJson(value);
        }
      });
      
      // Load symbol information
      final symbolJson = await rootBundle.loadString('assets/data/symbols_cultural_info.json');
      final symbolData = jsonDecode(symbolJson) as Map<String, dynamic>;
      
      symbolData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _symbolInfo[key] = SymbolCulturalInfo.fromJson(value);
        }
      });
      
      // Load regional information
      final regionalJson = await rootBundle.loadString('assets/data/regional_info.json');
      final regionalData = jsonDecode(regionalJson) as Map<String, dynamic>;
      
      regionalData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _regionalInfo[key] = RegionalInfo.fromJson(value);
        }
      });
      
      _loggingService.info('Cultural data loaded successfully', tag: 'CulturalContextService');
    } catch (e) {
      _loggingService.error('Error loading cultural data: $e', tag: 'CulturalContextService');
      // If loading from assets fails, initialize with default data
      _initializeDefaultData();
    }
  }
  
  /// Initialize with default cultural data
  void _initializeDefaultData() {
    _loggingService.info('Initializing default cultural data', tag: 'CulturalContextService');
    
    // Initialize pattern information
    _patternInfo = {
      'checker_pattern': PatternCulturalInfo(
        id: 'checker_pattern',
        name: 'Dame-Dame',
        englishName: 'Checkerboard',
        description: 'A simple checkerboard pattern representing duality and balance.',
        culturalSignificance: 'The Dame-Dame pattern symbolizes the balance between opposites in life - light and dark, joy and sorrow, the seen and unseen. It teaches that life contains complementary forces that work together in harmony.',
        region: 'Ashanti',
        difficulty: 'basic',
        historicalContext: 'One of the oldest and most fundamental Kente patterns, Dame-Dame has been used for centuries as both a standalone pattern and as a building block for more complex designs.',
        traditionalUses: ['Royal garments', 'Ceremonial cloth', 'Everyday wear'],
        relatedPatterns: ['zigzag_pattern'],
      ),
      'zigzag_pattern': PatternCulturalInfo(
        id: 'zigzag_pattern',
        name: 'Nkyinkyin',
        englishName: 'Zigzag',
        description: 'A zigzag pattern representing life\'s journey.',
        culturalSignificance: 'The Nkyinkyin pattern symbolizes life\'s twists and turns, adaptability, and resilience. It reminds us that life\'s path is rarely straight, but the journey itself has purpose.',
        region: 'Ashanti',
        difficulty: 'intermediate',
        historicalContext: 'This pattern emerged as weavers began to experiment with more complex designs beyond the basic checkerboard. It represents the increasing sophistication of Kente weaving techniques.',
        traditionalUses: ['Coming of age ceremonies', 'Journey celebrations', 'Life transition markers'],
        relatedPatterns: ['checker_pattern', 'diamonds_pattern'],
      ),
      'stripes_horizontal_pattern': PatternCulturalInfo(
        id: 'stripes_horizontal_pattern',
        name: 'Babadua',
        englishName: 'Horizontal Stripes',
        description: 'Horizontal stripes representing unity and cooperation.',
        culturalSignificance: 'The Babadua pattern symbolizes cooperation and community strength. Like bamboo poles that are stronger together, the pattern reminds us that people achieve more when working in harmony.',
        region: 'Ashanti',
        difficulty: 'basic',
        historicalContext: 'Horizontal striping is one of the foundational techniques in Kente weaving, often used as a background for more complex patterns.',
        traditionalUses: ['Community gatherings', 'Cooperative work events', 'Family reunions'],
        relatedPatterns: ['stripes_vertical_pattern'],
      ),
      'stripes_vertical_pattern': PatternCulturalInfo(
        id: 'stripes_vertical_pattern',
        name: 'Akyempem',
        englishName: 'Vertical Stripes',
        description: 'Vertical stripes representing individual strength and dignity.',
        culturalSignificance: 'The Akyempem pattern symbolizes individual strength, dignity, and personal achievement. It represents standing tall and upright in the face of challenges.',
        region: 'Ashanti',
        difficulty: 'basic',
        historicalContext: 'Vertical striping emerged as weavers began to experiment with the orientation of their looms and weaving techniques.',
        traditionalUses: ['Personal achievement celebrations', 'Coming of age ceremonies', 'Leadership installations'],
        relatedPatterns: ['stripes_horizontal_pattern'],
      ),
      'diamonds_pattern': PatternCulturalInfo(
        id: 'diamonds_pattern',
        name: 'Adweneasa',
        englishName: 'Diamond Pattern',
        description: 'Diamond shapes representing wisdom, creativity, and excellence.',
        culturalSignificance: 'The Adweneasa pattern symbolizes wisdom, creativity, and excellence in craftsmanship. The diamond shapes represent the multifaceted nature of knowledge and skill.',
        region: 'Ashanti',
        difficulty: 'advanced',
        historicalContext: 'This complex pattern was traditionally reserved for royalty and master weavers, showcasing the highest level of skill and artistry.',
        traditionalUses: ['Royal garments', 'Master weaver demonstrations', 'Special ceremonies'],
        relatedPatterns: ['zigzag_pattern', 'square_pattern'],
      ),
      'square_pattern': PatternCulturalInfo(
        id: 'square_pattern',
        name: 'Fahia Kotwere',
        englishName: 'Square Pattern',
        description: 'Concentric squares representing protection and security.',
        culturalSignificance: 'The Fahia Kotwere pattern symbolizes protection, security, and enclosed wisdom. The nested squares represent layers of protection around what is valuable.',
        region: 'Ashanti',
        difficulty: 'intermediate',
        historicalContext: 'This pattern evolved from simpler geometric designs as weavers developed more sophisticated techniques for creating enclosed spaces within their cloths.',
        traditionalUses: ['Protection ceremonies', 'Home blessings', 'Child naming ceremonies'],
        relatedPatterns: ['diamonds_pattern', 'checker_pattern'],
      ),
    };
    
    // Initialize color information
    _colorInfo = {
      'black': ColorCulturalInfo(
        id: 'black',
        name: 'Tuntum',
        englishName: 'Black',
        hexCode: '#000000',
        culturalMeaning: 'Black represents maturity, spiritual energy, and connection to ancestors. It symbolizes spiritual potency, antiquity, and the passage of time.',
        traditionalSources: ['Charcoal', 'Dark mud', 'Burnt wood'],
        traditionalUses: ['Funeral cloth', 'Elder garments', 'Spiritual ceremonies'],
        complementaryColors: ['gold', 'red'],
      ),
      'gold': ColorCulturalInfo(
        id: 'gold',
        name: 'Sikakɔkɔɔ',
        englishName: 'Gold',
        hexCode: '#FFD700',
        culturalMeaning: 'Gold represents royalty, wealth, high status, glory, and spiritual purity. It symbolizes the sun\'s life-giving warmth and the precious metal that once made the Ashanti kingdom prosperous.',
        traditionalSources: ['Yellow clay', 'Plant dyes', 'Minerals'],
        traditionalUses: ['Royal garments', 'High-status ceremonies', 'Wealth displays'],
        complementaryColors: ['black', 'green'],
      ),
      'red': ColorCulturalInfo(
        id: 'red',
        name: 'Kɔkɔɔ',
        englishName: 'Red',
        hexCode: '#FF0000',
        culturalMeaning: 'Red symbolizes political and spiritual potency, sacrifice, and bloodshed. It represents both the blood of sacrifice and the passionate life force that sustains the community.',
        traditionalSources: ['Red clay', 'Plant roots', 'Insects'],
        traditionalUses: ['War garments', 'Sacrificial ceremonies', 'Political statements'],
        complementaryColors: ['black', 'white'],
      ),
      'blue': ColorCulturalInfo(
        id: 'blue',
        name: 'Bruu',
        englishName: 'Blue',
        hexCode: '#0000FF',
        culturalMeaning: 'Blue represents peacefulness, harmony, love, and good fortune. It symbolizes the sky and the divine presence that watches over human affairs.',
        traditionalSources: ['Indigo plants', 'Minerals', 'Imported dyes'],
        traditionalUses: ['Peace ceremonies', 'Marriage cloth', 'Blessing ceremonies'],
        complementaryColors: ['white', 'gold'],
      ),
      'green': ColorCulturalInfo(
        id: 'green',
        name: 'Ahabammono',
        englishName: 'Green',
        hexCode: '#008000',
        culturalMeaning: 'Green symbolizes growth, fertility, prosperity, and renewal. It represents the lush vegetation that sustains life and the continuous renewal of nature.',
        traditionalSources: ['Plant leaves', 'Copper minerals', 'Mixed dyes'],
        traditionalUses: ['Harvest festivals', 'Fertility ceremonies', 'New beginnings'],
        complementaryColors: ['gold', 'white'],
      ),
      'white': ColorCulturalInfo(
        id: 'white',
        name: 'Fitaa',
        englishName: 'White',
        hexCode: '#FFFFFF',
        culturalMeaning: 'White represents purification, sanctification, and festive occasions. It symbolizes spiritual cleanliness, peace, and joy.',
        traditionalSources: ['Kaolin clay', 'Chalk', 'Natural cotton'],
        traditionalUses: ['Purification rituals', 'Festive occasions', 'Spirit communication'],
        complementaryColors: ['red', 'blue'],
      ),
    };
    
    // Initialize symbol information
    _symbolInfo = {
      'adinkrahene': SymbolCulturalInfo(
        id: 'adinkrahene',
        name: 'Adinkrahene',
        englishName: 'Chief of Adinkra Symbols',
        description: 'Concentric circles representing leadership and greatness.',
        culturalSignificance: 'The Adinkrahene symbol represents leadership, greatness, and the charismatic authority of a leader. As the concentric circles radiate from the center, they symbolize the expanding influence of effective leadership.',
        region: 'Ashanti',
        category: 'leadership',
        historicalContext: 'This symbol is considered the chief or leader of all Adinkra symbols, reflecting its importance in Akan visual language.',
        relatedSymbols: ['dwennimmen'],
      ),
      'dwennimmen': SymbolCulturalInfo(
        id: 'dwennimmen',
        name: 'Dwennimmen',
        englishName: 'Ram\'s Horns',
        description: 'Stylized ram\'s horns representing humility and strength.',
        culturalSignificance: 'The Dwennimmen symbol represents humility together with strength. It reminds us that even the strong should exercise humility, as the ram is powerful but submits to slaughter.',
        region: 'Ashanti',
        category: 'values',
        historicalContext: 'This symbol draws on the importance of livestock in traditional Akan society and the lessons learned from animal behavior.',
        relatedSymbols: ['adinkrahene', 'sankofa'],
      ),
      'sankofa': SymbolCulturalInfo(
        id: 'sankofa',
        name: 'Sankofa',
        englishName: 'Return and Get It',
        description: 'Bird with head turned backward, representing learning from the past.',
        culturalSignificance: 'The Sankofa symbol represents the importance of learning from the past. It teaches that we should reach back and gather the best of what our past has to teach us, so that we can achieve our full potential as we move forward.',
        region: 'Ashanti',
        category: 'wisdom',
        historicalContext: 'This symbol became particularly important during the Pan-African movement and continues to be significant in discussions of cultural heritage and identity.',
        relatedSymbols: ['dwennimmen'],
      ),
    };
    
    // Initialize regional information
    _regionalInfo = {
      'ashanti': RegionalInfo(
        id: 'ashanti',
        name: 'Ashanti',
        englishName: 'Ashanti Region',
        description: 'The historical heartland of the Ashanti Kingdom in central Ghana.',
        culturalSignificance: 'The Ashanti Region is the traditional home of Kente weaving, where the craft reached its highest development under royal patronage. The Ashanti Kingdom was known for its sophisticated political organization, gold wealth, and artistic achievements.',
        traditionalPatterns: ['checker_pattern', 'zigzag_pattern', 'diamonds_pattern'],
        traditionalColors: ['gold', 'black', 'green'],
        historicalContext: 'The Ashanti Kingdom emerged in the 17th century and became one of the most powerful states in West Africa. Kente weaving flourished under royal patronage, with certain patterns reserved exclusively for royalty.',
        notableLocations: ['Kumasi', 'Bonwire', 'Adanwomase'],
      ),
      'ewe': RegionalInfo(
        id: 'ewe',
        name: 'Ewe',
        englishName: 'Volta Region',
        description: 'The eastern region of Ghana, home to the Ewe people and their distinctive weaving tradition.',
        culturalSignificance: 'The Ewe people developed their own distinctive style of Kente weaving, characterized by more pictorial designs and narrative elements. Ewe Kente often incorporates symbols that tell specific stories or convey proverbs.',
        traditionalPatterns: ['stripes_horizontal_pattern', 'stripes_vertical_pattern'],
        traditionalColors: ['blue', 'red', 'white'],
        historicalContext: 'Ewe weaving traditions developed independently from Ashanti Kente but share some technical similarities. Ewe weavers were less constrained by royal regulations and could experiment more freely with designs.',
        notableLocations: ['Kpetoe', 'Ho', 'Agbozume'],
      ),
    };
  }
  
  /// Get cultural information for a specific pattern
  /// 
  /// If the pattern is not found in the local database, it will be generated using the Gemini API.
  Future<PatternCulturalInfo?> getPatternInfo(String patternId, {String language = 'en'}) async {
    // Check if pattern exists in local database
    final localInfo = _patternInfo[patternId.toLowerCase()];
    if (localInfo != null) {
      return localInfo;
    }
    
    // If not found locally, generate using Gemini
    try {
      final contextData = await _geminiService.generateCulturalContext(
        patternId: patternId,
        language: language,
        includeColorMeanings: true,
        includeHistoricalContext: true,
      );
      
      // Convert to PatternCulturalInfo
      final patternName = patternId
          .split('_')
          .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
          .join(' ');
      
      final patternInfo = PatternCulturalInfo(
        id: patternId,
        name: contextData['title'] ?? patternName,
        englishName: patternName,
        description: contextData['description'] ?? 'A traditional Kente pattern.',
        culturalSignificance: contextData['culturalSignificance'] ?? contextData['description'] ?? 'This pattern has cultural significance in Kente weaving.',
        region: 'Ashanti', // Default
        difficulty: 'intermediate', // Default
        historicalContext: contextData['historicalContext'] ?? 'This pattern has historical significance in Kente weaving.',
        traditionalUses: contextData['traditionalUse'] != null ? [contextData['traditionalUse']] : ['Traditional ceremonies'],
        relatedPatterns: [],
      );
      
      // Cache the result
      _patternInfo[patternId.toLowerCase()] = patternInfo;
      
      return patternInfo;
    } catch (e) {
      _loggingService.error('Error generating pattern info: $e', tag: 'CulturalContextService');
      return null;
    }
  }
  
  /// Get cultural information for a specific color
  Future<ColorCulturalInfo?> getColorInfo(String colorId) {
    return Future.value(_colorInfo[colorId.toLowerCase()]);
  }
  
  /// Get cultural information for a specific symbol
  Future<SymbolCulturalInfo?> getSymbolInfo(String symbolId) {
    return Future.value(_symbolInfo[symbolId.toLowerCase()]);
  }
  
  /// Get cultural information for a specific region
  Future<RegionalInfo?> getRegionalInfo(String regionId) {
    return Future.value(_regionalInfo[regionId.toLowerCase()]);
  }
  
  /// Get cultural information for a pattern combination
  Future<String> getCombinationMeaning(List<String> patternIds, {String language = 'en'}) async {
    if (patternIds.isEmpty) return '';
    
    // If only one pattern, return its significance
    if (patternIds.length == 1) {
      final pattern = await getPatternInfo(patternIds.first, language: language);
      return pattern?.culturalSignificance ?? '';
    }
    
    // For multiple patterns, generate a combined meaning
    final patterns = await Future.wait(
      patternIds.map((id) => getPatternInfo(id, language: language))
    );
    
    final validPatterns = patterns.where((p) => p != null).cast<PatternCulturalInfo>().toList();
    
    if (validPatterns.isEmpty) return '';
    
    // Try to generate a combined meaning using Gemini
    try {
      final prompt = '''
      Analyze this combination of Kente patterns in $language:
      ${validPatterns.map((p) => '- ${p.name}: ${p.description}').join('\n')}
      
      Provide a cultural interpretation of what this combination might symbolize or represent.
      Focus on how these patterns might work together to create a unified meaning.
      Keep the explanation appropriate for children aged 7-12.
      ''';
      
      final response = await _geminiService.generateText(prompt, language: language);
      return response;
    } catch (e) {
      _loggingService.error('Error generating combination meaning: $e', tag: 'CulturalContextService');
      
      // Generate a combined meaning based on the patterns
      return 'This combination of ${validPatterns.map((p) => p.name).join(', ')} '
          'creates a rich tapestry of meaning. '
          '${validPatterns.map((p) => p.culturalSignificance).join(' ')}';
    }
  }
  
  /// Get cultural information for a color combination
  Future<String> getColorCombinationMeaning(List<String> colorIds, {String language = 'en'}) async {
    if (colorIds.isEmpty) return '';
    
    // If only one color, return its meaning
    if (colorIds.length == 1) {
      final color = _colorInfo[colorIds.first.toLowerCase()];
      return color?.culturalMeaning ?? '';
    }
    
    // For multiple colors, get the info for each
    final colors = colorIds
        .map((id) => _colorInfo[id.toLowerCase()])
        .where((c) => c != null)
        .cast<ColorCulturalInfo>()
        .toList();
    
    if (colors.isEmpty) return '';
    
    // Try to generate a combined meaning using Gemini
    try {
      final prompt = '''
      Analyze this combination of colors in Kente weaving in $language:
      ${colors.map((c) => '- ${c.englishName} (${c.name}): ${c.culturalMeaning}').join('\n')}
      
      Provide a cultural interpretation of what this color combination might symbolize or represent.
      Focus on how these colors might work together to create a unified meaning.
      Keep the explanation appropriate for children aged 7-12.
      ''';
      
      final response = await _geminiService.generateText(prompt, language: language);
      return response;
    } catch (e) {
      _loggingService.error('Error generating color combination meaning: $e', tag: 'CulturalContextService');
      
      // Generate a combined meaning based on the colors
      return 'This combination of ${colors.map((c) => c.name).join(', ')} '
          'creates a powerful visual statement. '
          '${colors.map((c) => c.culturalMeaning).join(' ')}';
    }
  }
  
  /// Get educational fact about Kente weaving
  Future<String> getRandomEducationalFact({String language = 'en'}) async {
    final facts = [
      'Kente cloth was originally worn only by royalty and spiritual leaders for special occasions.',
      'Traditional Kente is woven on a horizontal loom in narrow strips that are later sewn together.',
      'Each Kente pattern has a name and meaning, often inspired by proverbs, historical events, or natural phenomena.',
      'The colors in Kente cloth are not just decorative but carry specific cultural meanings and messages.',
      'The word "Kente" comes from the Akan word "kenten," which means basket, referring to the basket-like pattern of the weaving.',
      'Kente weaving is traditionally done by men, while women typically handle the spinning of the thread.',
      'A full traditional Kente cloth can take several weeks to months to complete by hand.',
      'There are over 300 different Kente patterns, each with its own name and symbolic meaning.',
      'Kente patterns are often named after proverbs, historical events, important people, or natural phenomena.',
      'The most prestigious Kente cloths use silk threads, though cotton is more commonly used today.',
    ];
    
    // Return a random fact
    final randomFact = facts[DateTime.now().millisecondsSinceEpoch % facts.length];
    
    // If language is English, return directly
    if (language == 'en') {
      return randomFact;
    }
    
    // Otherwise, translate using Gemini
    try {
      final prompt = '''
      Translate this educational fact about Kente weaving to $language:
      
      $randomFact
      
      Keep the translation appropriate for children aged 7-12.
      ''';
      
      final response = await _geminiService.generateText(prompt, language: language);
      return response;
    } catch (e) {
      _loggingService.error('Error translating educational fact: $e', tag: 'CulturalContextService');
      return randomFact; // Fallback to English
    }
  }
  
  /// Get a cultural proverb related to a concept
  Future<String> getProverbForConcept(String concept, {String language = 'en'}) async {
    final proverbs = {
      'learning': 'Knowledge is like a garden; if it is not cultivated, it cannot be harvested.',
      'patience': 'No matter how long the night, the day is sure to come.',
      'wisdom': 'The ruin of a nation begins in the homes of its people.',
      'community': 'If you want to go fast, go alone. If you want to go far, go together.',
      'perseverance': 'If you are in a hurry, you will use a rough road.',
      'planning': 'A good name is better than riches.',
      'leadership': 'The king\'s speech is not like water spilled on the ground which cannot be gathered.',
      'creativity': 'The palm tree grows in the forest by itself, but the coconut tree is planted by humans.',
      'balance': 'It is the calm and silent water that drowns a man.',
      'tradition': 'When you follow in the path of your father, you learn to walk like him.',
    };
    
    // Get the proverb for the concept
    final proverb = proverbs[concept.toLowerCase()] ?? 
        'A wise person adapts like the Nkyinkyin pattern, navigating life\'s twists and turns.';
    
    // If language is English, return directly
    if (language == 'en') {
      return proverb;
    }
    
    // Otherwise, translate using Gemini
    try {
      final prompt = '''
      Translate this African proverb to $language:
      
      $proverb
      
      Keep the translation appropriate for children aged 7-12.
      ''';
      
      final response = await _geminiService.generateText(prompt, language: language);
      return response;
    } catch (e) {
      _loggingService.error('Error translating proverb: $e', tag: 'CulturalContextService');
      return proverb; // Fallback to English
    }
  }
}

/// Cultural information about a Kente pattern
class PatternCulturalInfo {
  /// Pattern identifier
  final String id;
  
  /// Traditional name in Akan language
  final String name;
  
  /// English translation of the name
  final String englishName;
  
  /// Brief description of the pattern
  final String description;
  
  /// Cultural significance and meaning
  final String culturalSignificance;
  
  /// Region of origin
  final String region;
  
  /// Difficulty level (basic, intermediate, advanced, master)
  final String difficulty;
  
  /// Historical context and origin
  final String historicalContext;
  
  /// Traditional uses of the pattern
  final List<String> traditionalUses;
  
  /// Related patterns
  final List<String> relatedPatterns;

  const PatternCulturalInfo({
    required this.id,
    required this.name,
    required this.englishName,
    required this.description,
    required this.culturalSignificance,
    required this.region,
    required this.difficulty,
    required this.historicalContext,
    required this.traditionalUses,
    required this.relatedPatterns,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'englishName': englishName,
      'description': description,
      'culturalSignificance': culturalSignificance,
      'region': region,
      'difficulty': difficulty,
      'historicalContext': historicalContext,
      'traditionalUses': traditionalUses,
      'relatedPatterns': relatedPatterns,
    };
  }

  /// Create from JSON
  factory PatternCulturalInfo.fromJson(Map<String, dynamic> json) {
    return PatternCulturalInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      description: json['description'] as String,
      culturalSignificance: json['culturalSignificance'] as String,
      region: json['region'] as String,
      difficulty: json['difficulty'] as String,
      histor
