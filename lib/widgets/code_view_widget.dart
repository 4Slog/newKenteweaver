import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/block_model.dart';
import '../theme/app_theme.dart';

/// A widget for displaying block code in textual format with syntax highlighting.
/// 
/// Supports displaying code in different languages (block code, Python).
/// Also provides copy-to-clipboard functionality.
class CodeViewWidget extends StatefulWidget {
  /// The blocks to display as code
  final List<Map<String, dynamic>> blocks;
  
  /// The language to display the code in ('blocks', 'python', etc.)
  final String language;
  
  /// Whether to show a header with language and copy button
  final bool showHeader;
  
  /// Whether to show line numbers
  final bool showLineNumbers;
  
  /// Additional styling for the code container
  final BoxDecoration? decoration;
  
  /// Callback when code is copied
  final Function()? onCopy;

  const CodeViewWidget({
    Key? key,
    required this.blocks,
    this.language = 'blocks',
    this.showHeader = true,
    this.showLineNumbers = true,
    this.decoration,
    this.onCopy,
  }) : super(key: key);

  @override
  State<CodeViewWidget> createState() => _CodeViewWidgetState();
}

class _CodeViewWidgetState extends State<CodeViewWidget> {
  /// Flag for showing copy success message
  bool _showCopySuccess = false;
  
  /// Timer for hiding the copy success message
  late String _codeText;

  @override
  void initState() {
    super.initState();
    _codeText = _generateCodeText();
  }
  
  @override
  void didUpdateWidget(CodeViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blocks != widget.blocks || 
        oldWidget.language != widget.language) {
      _codeText = _generateCodeText();
    }
  }

  /// Generates the code text representation based on the current language
  String _generateCodeText() {
    if (widget.language == 'python') {
      return _generatePythonCode();
    } else {
      return _generateBlockCode();
    }
  }

  /// Generates Python equivalent code
  String _generatePythonCode() {
    final StringBuffer code = StringBuffer();
    code.writeln('# Generated Python code from Kente Code Weaver blocks');
    code.writeln('# Each block represents a weaving pattern or command');
    code.writeln();
    
    // Track indentation level
    int indentLevel = 0;
    
    // Process each block
    for (int i = 0; i < widget.blocks.length; i++) {
      final block = widget.blocks[i];
      final String type = block['type'] ?? 'unknown';
      final String subtype = block['subtype'] ?? '';
      final Map<String, dynamic> properties = block['properties'] ?? {};
      
      // Get indent string based on current level
      final indent = '    ' * indentLevel;
      
      switch (type.toLowerCase()) {
        case 'pattern':
          final patternName = _getPatternName(subtype);
          final value = properties['value'] ?? 'default';
          code.writeln('${indent}# Create ${patternName.replaceAll('_', ' ')} pattern');
          code.writeln('${indent}pattern = KentePattern("$value")');
          break;
          
        case 'color':
          final colorName = _getColorName(subtype);
          final colorValue = properties['color'] ?? '0';
          code.writeln('${indent}# Apply $colorName color');
          code.writeln('${indent}pattern.set_color("$colorValue")');
          break;
          
        case 'structure':
          if (subtype.contains('loop')) {
            final repetitions = properties['value'] ?? '3';
            code.writeln('${indent}# Repeat pattern');
            code.writeln('${indent}for i in range($repetitions):');
            indentLevel++;
          } else if (subtype.contains('row')) {
            code.writeln('${indent}# Create row');
            code.writeln('${indent}row = KenteRow()');
          } else if (subtype.contains('column')) {
            code.writeln('${indent}# Create column');
            code.writeln('${indent}column = KenteColumn()');
          }
          break;
          
        case 'condition':
          code.writeln('${indent}# Conditional pattern');
          code.writeln('${indent}if condition:');
          indentLevel++;
          break;
          
        case 'end':
          // End blocks reduce indentation
          if (indentLevel > 0) {
            indentLevel--;
          }
          break;
          
        default:
          code.writeln('${indent}# Unknown block: $type');
      }
      
      // Add blank line between blocks for readability
      if (i < widget.blocks.length - 1) {
        code.writeln();
      }
    }
    
    // Final line to show the pattern
    code.writeln('\n# Display final pattern');
    code.writeln('display(pattern)');
    
    return code.toString();
  }

  /// Generates block code representation
  String _generateBlockCode() {
    final StringBuffer code = StringBuffer();
    code.writeln('// Kente Code Weaver Block Representation');
    code.writeln('// Each line represents a weaving pattern or command');
    code.writeln();
    
    // Process each block
    for (int i = 0; i < widget.blocks.length; i++) {
      final block = widget.blocks[i];
      final String type = block['type'] ?? 'unknown';
      final String subtype = block['subtype'] ?? '';
      final Map<String, dynamic> properties = block['properties'] ?? {};
      
      switch (type.toLowerCase()) {
        case 'pattern':
          final patternName = _getPatternName(subtype);
          final value = properties['value'] ?? 'default';
          code.writeln('PATTERN[$patternName]: $value');
          break;
          
        case 'color':
          final colorName = _getColorName(subtype);
          final colorValue = properties['color'] ?? '0';
          code.writeln('COLOR[$colorName]: $colorValue');
          break;
          
        case 'structure':
          if (subtype.contains('loop')) {
            final repetitions = properties['value'] ?? '3';
            code.writeln('REPEAT: $repetitions times {');
          } else if (subtype.contains('row')) {
            code.writeln('ROW {');
          } else if (subtype.contains('column')) {
            code.writeln('COLUMN {');
          }
          break;
          
        case 'end':
          code.writeln('}');
          break;
          
        case 'condition':
          final condition = properties['condition'] ?? 'true';
          code.writeln('IF: $condition {');
          break;
          
        default:
          code.writeln('BLOCK[$type]: ${properties.toString()}');
      }
    }
    
    return code.toString();
  }

  /// Gets a readable pattern name from a subtype
  String _getPatternName(String subtype) {
    // Convert pattern IDs to readable names
    switch (subtype.toLowerCase()) {
      case 'checker_pattern':
        return 'Dame-Dame';
      case 'zigzag_pattern':
        return 'Nkyinkyim';
      case 'stripes_horizontal_pattern':
        return 'Babadua';
      case 'stripes_vertical_pattern':
        return 'Kubi';
      case 'square_pattern':
        return 'Eban';
      case 'diamonds_pattern':
        return 'Obaakofo';
      default:
        // Convert subtype to title case for readability
        return subtype.split('_').map((word) => 
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
        ).join(' ');
    }
  }
  
  /// Gets a readable color name from a subtype
  String _getColorName(String subtype) {
    // Convert color IDs to readable names
    switch (subtype.toLowerCase()) {
      case 'shuttle_black':
        return 'Black';
      case 'shuttle_gold':
        return 'Gold';
      case 'shuttle_red':
        return 'Red';
      case 'shuttle_blue':
        return 'Blue';
      case 'shuttle_green':
        return 'Green';
      default:
        // Convert subtype to title case for readability
        return subtype.split('_').map((word) => 
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
        ).join(' ');
    }
  }

  /// Copy code to clipboard
  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _codeText));
    
    setState(() {
      _showCopySuccess = true;
    });
    
    // Hide the success message after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCopySuccess = false;
        });
      }
    });
    
    // Call the onCopy callback if provided
    if (widget.onCopy != null) {
      widget.onCopy!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.decoration ?? BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Optional header with language and copy button
          if (widget.showHeader)
            _buildHeader(),
            
          // Code content
          Expanded(
            child: _buildCodeContent(),
          ),
        ],
      ),
    );
  }
  
  /// Builds the header with language display and copy button
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language display
          Text(
            widget.language == 'python' ? 'Python' : 'Kente Block Code',
            style: TextStyle(
              color: Colors.grey[200],
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Copy button
          TextButton.icon(
            icon: _showCopySuccess
                ? const Icon(Icons.check, color: Colors.green)
                : const Icon(Icons.content_copy, color: Colors.grey),
            label: Text(
              _showCopySuccess ? 'Copied!' : 'Copy',
              style: TextStyle(
                color: _showCopySuccess ? Colors.green : Colors.grey[200],
              ),
            ),
            onPressed: _copyToClipboard,
          ),
        ],
      ),
    );
  }
  
  /// Builds the main code content area
  Widget _buildCodeContent() {
    final codeLines = _codeText.split('\n');
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: widget.showLineNumbers
            ? _buildCodeWithLineNumbers(codeLines)
            : _buildPlainCode(codeLines),
      ),
    );
  }
  
  /// Builds code content with line numbers
  Widget _buildCodeWithLineNumbers(List<String> codeLines) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line numbers
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
            codeLines.length,
            (i) => Container(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Code text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: codeLines.map((line) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: _buildSyntaxHighlightedLine(line),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  /// Builds code content without line numbers
  Widget _buildPlainCode(List<String> codeLines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: codeLines.map((line) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: _buildSyntaxHighlightedLine(line),
        );
      }).toList(),
    );
  }
  
  /// Applies syntax highlighting to a single line
  Widget _buildSyntaxHighlightedLine(String line) {
    // Apply language-specific syntax highlighting
    if (widget.language == 'python') {
      return _buildPythonSyntaxHighlighting(line);
    } else {
      return _buildBlockCodeSyntaxHighlighting(line);
    }
  }
  
  /// Applies Python syntax highlighting
  Widget _buildPythonSyntaxHighlighting(String line) {
    // Simple Python syntax highlighting
    if (line.trim().startsWith('#')) {
      // Comments
      return Text(
        line,
        style: TextStyle(
          color: Colors.green[300],
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    } else if (line.contains('=')) {
      // Assignment statements
      final parts = line.split('=');
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          children: [
            TextSpan(text: parts[0], style: TextStyle(color: Colors.grey[200])),
            const TextSpan(text: '=', style: TextStyle(color: Colors.white)),
            TextSpan(
              text: parts.length > 1 ? parts[1] : '',
              style: TextStyle(color: line.contains('"') ? Colors.orange[300] : Colors.cyan[300]),
            ),
          ],
        ),
      );
    } else if (line.contains('for') || line.contains('if') || line.contains('else:')) {
      // Control flow
      return Text(
        line,
        style: TextStyle(
          color: AppTheme.kenteGold,
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (line.contains('(') && line.contains(')')) {
      // Function calls
      return Text(
        line,
        style: TextStyle(
          color: Colors.cyan[300],
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    } else {
      // Default
      return Text(
        line,
        style: TextStyle(
          color: Colors.grey[200],
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    }
  }
  
  /// Applies block code syntax highlighting
  Widget _buildBlockCodeSyntaxHighlighting(String line) {
    // Simple block code syntax highlighting
    final trimLine = line.trim();
    
    if (trimLine.startsWith('//')) {
      // Comments
      return Text(
        line,
        style: TextStyle(
          color: Colors.green[300],
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    } else if (trimLine.startsWith('PATTERN')) {
      // Pattern blocks
      return Text(
        line,
        style: TextStyle(
          color: Colors.blue[300],
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (trimLine.startsWith('COLOR')) {
      // Color blocks
      // Extract the color name to determine text color
      Color textColor = Colors.orange;
      if (trimLine.contains('Black')) {
        textColor = Colors.grey;
      } else if (trimLine.contains('Gold')) {
        textColor = AppTheme.kenteGold;
      } else if (trimLine.contains('Red')) {
        textColor = Colors.red;
      } else if (trimLine.contains('Blue')) {
        textColor = Colors.blue;
      } else if (trimLine.contains('Green')) {
        textColor = Colors.green;
      }
      
      return Text(
        line,
        style: TextStyle(
          color: textColor,
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (trimLine.startsWith('REPEAT') || 
               trimLine.startsWith('ROW') || 
               trimLine.startsWith('COLUMN')) {
      // Structure blocks
      return Text(
        line,
        style: TextStyle(
          color: AppTheme.kenteGold,
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (trimLine.startsWith('IF')) {
      // Conditional blocks
      return Text(
        line,
        style: TextStyle(
          color: Colors.purple[300],
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (trimLine == '}') {
      // Closing braces
      return Text(
        line,
        style: TextStyle(
          color: AppTheme.kenteGold,
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      // Default
      return Text(
        line,
        style: TextStyle(
          color: Colors.grey[200],
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    }
  }
}

/// Extension for using CodeViewWidget with BlockCollection
extension CodeViewBlockExtension on CodeViewWidget {
  /// Create a code view widget from a BlockCollection
  static CodeViewWidget fromBlockCollection({
    required BlockCollection blocks,
    String language = 'blocks',
    bool showHeader = true,
    bool showLineNumbers = true,
    BoxDecoration? decoration,
    Function()? onCopy,
  }) {
    // Convert BlockCollection to the required format
    final List<Map<String, dynamic>> blockData = blocks.blocks.map((block) {
      return {
        'type': block.type.toString().split('.').last,
        'subtype': block.subtype,
        'properties': block.properties,
      };
    }).toList();
    
    return CodeViewWidget(
      blocks: blockData,
      language: language,
      showHeader: showHeader,
      showLineNumbers: showLineNumbers,
      decoration: decoration,
      onCopy: onCopy,
    );
  }
}